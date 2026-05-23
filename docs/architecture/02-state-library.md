# 02 — State Library & Status Effects

## Current state

### Where it lives
`src/ReplicatedStorage/Modules/Shared/StateLibrary/` — `init.luau`, `StatePresets.luau`. Consumed by `src/ServerScriptService/Core/` and every fighting style under `Core/AbilityAPI/`.

### Storage model
Per-player Folder (`Player.States`) built from `StatePresets`. Each state is itself a Folder containing:
- `Base` (BoolValue) — active/inactive flag
- `Begin` (NumberValue) — server timestamp when set
- `Duration` (NumberValue) — timeout in seconds
- `Category` (StringValue) — one of `NormalInteger`, `SpecialInteger`, `Boolean`
- Ad-hoc metadata children: `BlockAmount`, `MaxBlocks`, `LastAttackedBy`, `JumpPower`, `WalkSpeed`, etc.

Because it's instance-based, the entire state tree replicates automatically to the owning client.

### Category semantics (current, intentionally quoted for clarity)
- **`NormalInteger`** — *active when expired.* `now - Begin >= Duration`. Used for "this thing is done and now applies" semantics (CombatLog kill-credit window, IFrame end, Endlag complete).
- **`SpecialInteger`** — *active when not expired.* `now - Begin <= Duration`. Used for "this thing is in progress" (Attacking, Casting, Speed buff/debuff).
- **`Boolean`** — raw `Base.Value`. Used for instant toggles (Blocking, Charging, Safezone).

### Gating — `StateLibrary.IsValidAction`
`StatePresets.ActionFlags["Ability"]` is a table of `{StateName = requiredValue}`. `IsValidAction(Player, "Ability")` iterates the table and confirms every named state currently evaluates to its required value. If any fails, the action is gated.

### Mutation — `StateLibrary.ModifyState`
`(Player, StateName, valueOrDuration, extraTable?)` writes through to the right child Value(s). Code is **required** to go through this — direct writes to `Player.States` bypass the comparison logic.

## Problems

1. **`NormalInteger` semantics are inverted from intuition.** "Active when expired" reads backwards. Devs onboarding to the code routinely get it wrong; refactors flip the inequality and everything breaks subtly.
2. **No event bus.** Watchers must connect to `.Base.Changed` per state or poll. UI has no clean "subscribe to all state changes" path. HUD that wants to show stun, knocked, block-meter all has to register multiple listeners.
3. **Metadata schema sprawl.** `BlockAmount` lives under `Blocking`; `LastAttackedBy` lives under `CombatLog`; `WalkSpeed` lives under `Speed`. There's no contract for what metadata a state has, just convention.
4. **Stacking is undefined.** Two `ModifyState(Player, "Stunned", 1.5)` calls back-to-back: does the second extend? Reset? Add? Reading the code, last-write-wins (the second `Begin` overwrites). No way to express "refresh only if longer".
5. **No immunity / resistance layer.** Want a character to be stun-immune for 5s after a knock? Currently bolted on at every call-site instead of one centralized check.
6. **Stale entries linger.** When a `SpecialInteger` expires, nothing clears `Base.Value`. `IsValidAction` works by comparing timestamps, but readers that check `Base.Value` directly see stale `true`.
7. **Conflates two concepts.** "Player state" (Blocking, Charging, Knocked) and "applied status effect" (Stunned, Burned, Frozen) are different in lifetime and ownership but jammed into the same instance hierarchy.

## fruit reference pattern

Fruit splits the concern explicitly into **two systems**:

### `StateManager` (gameplay states owned by the player)
`SetState(Player, "Stunned", Duration)` / `ClearState(Player, "Flying")`. Used for control-state things: Stunned, Flying, Charging, Casting. Server-authoritative, queryable from server logic.

```lua
-- From fruit/ServerScriptService/Server/Abilities/Stun Library.luau
function module:stun(Player, Duration)
    StateManager:ClearState(Player, "Flying")
    StateManager:ClearState(Player, "Charging")
    StateManager:SetState(Player, "Stunned", Duration)
end
```

### `StatusEffectHandler` (timed effects applied to a Character)
`Apply(AttackerPlayer, TargetCharacter, EffectType, MoveDamage, PotencyMultiplier, DurationMultiplier)`. Used for: Burn, Bleed, Slow, Poison, etc. — effects with ticks, potency, and source attribution.

Key design choices in fruit (`ServerScriptService/Server/Main Mechanics/StatusEffectHandler.luau`):

- **Per-effect config** at module-load: `Cfg.Duration`, `Cfg.Stacking`, `Cfg.SpeedReduction`, tick interval, etc.
- **Explicit stacking modes**: `"None"` (reject if exists), `"Refresh"` (reset timer), `"AddHalf"` (add ½ of new duration to remainder).
- **Immunities table** (`Immunities[TargetCharacter][EffectType]`) — central, not per-call-site.
- **Active table** keyed by `Character`, value is `{AttackerPlayer, Duration, Elapsed, LastTick, MoveDamage, PotencyMultiplier, ...}`. Pure Lua table — no instance mirror.
- **Tick-driven** via a Heartbeat loop or per-effect connection — `setupConnections(TargetCharacter)`.

### Replication
Visual feedback is fired explicitly via the networking layer:
```lua
Network.Effects:Fire(Network.AllPlayers(), {
    Ability = "Electro Stun",
    Data = { Target = Player.Character, StunDuration = 2 },
})
```
Clients consume the typed bridge payload and run their own VFX. State itself is not auto-replicated — the client trusts the server's effect broadcast.

## Recommended replacement for shonclash

### Split into two modules

```
src/ReplicatedStorage/Modules/Shared/Combat/
  StateManager.luau          (gameplay states — Stunned, Flying, Charging, Knocked, Blocking)
  StatusEffectHandler.luau   (timed effects — Burned, Bleeding, Slowed, Frozen)
  EffectConfig.luau          (per-effect config tables: Duration, Stacking, Ticks, etc.)
```

### Data model
- **Pure Lua tables** keyed by `Player` (for states) and `Character` (for effects). No instance folders.
- A `Player.States` Folder is no longer created at all (cleanup happens in [`01-data-layer.md`](01-data-layer.md) wave or alongside this).

### Replication
- State changes do **not** auto-replicate. The client receives:
  1. **Effect broadcasts** via the typed network layer when something visible happens (see [`04-networking.md`](04-networking.md)).
  2. **Selective state mirrors** for HUD-relevant states (Knocked, Stunned, Blocking) via Replica, so the HUD can show indicators without polling. Non-HUD states (CombatLog, Endlag, IFrame) stay server-only.

### Gating API
- Replace `IsValidAction(Player, ActionCategory)` with the same interface, backed by a single table lookup on the new pure-Lua state table. Add `Can(player, "ability")`, `Can(player, "block")`, `Can(player, "move")` as convenience helpers.
- Drop the `NormalInteger` vs `SpecialInteger` distinction entirely. All states are either:
  - **Timed** (`{ active = true, until_t = N }`) — `active and now < until_t`
  - **Flag** (`{ active = bool }`) — boolean.

### Stacking semantics
Inherit fruit's three modes (`None` / `Refresh` / `AddHalf`) plus add `MaxStack` for counters (e.g. bleed stacks).

### Immunities
First-class: `StateManager:GrantImmunity(player, "Stunned", 5)` instead of bolted-on per call-site.

### Event bus
- `StateManager.Changed:Connect(function(player, stateName, active) end)` — single signal.
- `StatusEffectHandler.Applied:Connect(...)`, `.Expired:Connect(...)`, `.Ticked:Connect(...)`.

### Migration order

1. **Build the new modules side-by-side** at the path above. Old `StateLibrary` keeps working.
2. **Rewrite the gating helpers** so `StateLibrary.IsValidAction` proxies into the new `StateManager.Can(...)`. Existing call-sites keep working unchanged.
3. **Migrate fighting styles one at a time** — replace their `StateLibrary.ModifyState` calls with `StateManager.SetState` / `StatusEffectHandler.Apply` as semantically appropriate (clean re-classification: which calls are "gameplay state" vs "status effect").
4. **Delete `StateLibrary`** and the `Player.States` folder creation once nothing references them.

## Related docs

- [`04-networking.md`](04-networking.md) — typed Effects bridge for state-change visual broadcasts.
- [`03-combat-abilities.md`](03-combat-abilities.md) — the biggest consumer of state gating.
- [`05-ui-hud.md`](05-ui-hud.md) — HUD's Knocked/Stunned indicators subscribe to the StateManager event bus.
