# 03 — Combat / Abilities Pipeline

## Current state

Shonen Clash has **two coexisting ability dispatch patterns**, plus a damage layer they both share.

### Pattern A — Filesystem-based "Fighting Styles" (primary)

- **Server logic:** `src/ServerScriptService/Core/AbilityAPI/Fighting Styles/<Name>.luau` (Sasuke, Sanji, Endeavor, Whitebeard, Deku, Melee, Dual Katana).
- **Data tables:** `src/ReplicatedStorage/Modules/Shared/Database/Abilities/<Name>.luau` — pure tables, `{Name, Chargeable, Damage, Range, Cooldown, Stamina, Endlag, Mastery, ActionFlag, Stationary?}`.
- **Shape:** Each fighting-style file returns a table keyed by ability name. Chargeable abilities nest `Charge`/`Release` subfunctions. Non-chargeable abilities are flat handlers.
- **Dispatcher:** Not explicitly in the repo. Triggered via the `AbilityRequest` RemoteEvent, then routed through some Studio-installed external loader.
- **Replication of effects:** Each handler calls `NetworkStream.FireAllClients(Character, "Effect", delay_ms, effectData)`. The client's `Remotes.Effect` listener routes by `effectData.Category` + `effectData.Function`.
- **Cooldown:** `DebounceAPI.ApplyCooldown(Player, script.Name, "AbilityName")`. Stamina check happens before the handler runs (also outside the repo's visible code).
- **Damage:** `DamageAPI.InflictDamage(Character, Target, AbilityData, source)` — server-authoritative; returns `true` if the hit landed. Internally clamps HP, applies knockback, mutates states.

### Pattern B — Workspace move-script dispatcher (Hellflame, Hollow1)

- **Scripts:** `src/Workspace/Hellflame/HellflameServerScripts/MOVE1.luau` .. `MOVE6.luau`, `AWAKENING.luau`. Paired with `HellflameClientScripts/*`.
- **Signature:** Every move returns a function `(Character, Input, MoveState, ReplicateMove, Timer, Modules, ClientData, FiredData)`.
- **Loader:** Not in repo. A Studio-installed package finds these scripts at runtime, hands the move state machine through, dispatches input.
- **State machine helpers (provided by external loader):** `MoveState:InCooldown()`, `MoveState:SetCooldown()`, `Timer.Wait(...)`, `ReplicateMove(...)`.
- **Two parallel client/server trees** — server side calls damage, client side renders effects. Mirror layout, separate code.

### Shared primitives
- `src/ReplicatedStorage/Modules/Shared/Database/Global/Combat.luau` — combat constants.
- `src/ReplicatedStorage/Modules/Shared/Database/KeybindManager.luau` — input → ability mapping.
- `src/ServerScriptService/Core/Mechanics/Damage API.luau` (≈"Damage API") — single authoritative damage entry point. Both patterns route here.

## Problems

1. **Two patterns with different signatures.** A new ability has to choose which loader, with different state-machine semantics. Reviewers can't reason about the codebase as one system.
2. **Opaque external loader.** Both patterns rely on Studio-installed code that's not versioned in the repo. Anyone cloning the repo can't run the game without that black-box dependency. Refactoring is unsafe because the loader contract is invisible.
3. **Charge/Release re-implemented per ability.** Each Chargeable ability re-defines its own `Charge` and `Release` functions; the framework gives no shared state machine for "held button → charge meter → release threshold".
4. **Hellflame moves duplicate dispatch logic.** Cooldown via `MoveState`, replication via `ReplicateMove`, damage via direct calls — same concept, separate plumbing from Pattern A.
5. **Cooldown + stamina enforcement is split.** `DebounceAPI` for cooldown, stamina gating outside the repo. If either fails silently, the user sees the ability "not fire" with no diagnostic.
6. **Visual broadcast is per-handler, not per-framework.** A handler that forgets to call `NetworkStream.FireAllClients` produces a silent ability — works on the server, invisible on the client.
7. **No ability registry.** "What abilities exist?" is answered by scanning two directory trees with different schemas.

## fruit reference pattern

Fruit's combat lives at `ServerScriptService/Server/Abilities/` and uses the typed networking layer ([`04-networking.md`](04-networking.md)) plus a `StateManager` + `StatusEffectHandler` split ([`02-state-library.md`](02-state-library.md)).

Concrete pieces (verified via Nia greps and shared-codebase fragments):

- **Server-side ability modules** at `ServerScriptService/Server/Abilities/<Name>.luau` (Stun Library, etc.). Each module exposes a small surface (e.g. `stun`, `electroStun`).
- **Effect broadcasts via typed BridgeNet2 bridge** — `Network.Effects:Fire(Network.AllPlayers(), { Ability = "...", Data = {...} })`. One bridge for all visual effects; routed client-side by `Ability` name.
- **State mutation goes through StateManager**, not direct instance writes.
- **Status effects (DoT, slows) live in StatusEffectHandler** with `Apply(attacker, target, effectType, damage, potencyMul, durationMul)`. Stacking is config-driven (`None`/`Refresh`/`AddHalf`).
- **Damage dispatch** routes through a damage-helper module that consults the same StateManager / StatusEffectHandler for invulnerability, blocking, etc.

⚠️ I do not have a fully reconstructed dispatcher signature from fruit's combat layer — Nia returned authentication errors on follow-up grep attempts. The `Stun Library` excerpt confirms the *style* (small per-domain modules, typed bridge for effects, server-authoritative state mutations) but the precise input → handler → effect contract for fruit abilities was not fully exfiltrated. The recommendation below is therefore framework-shaped, not a direct port.

## Recommended replacement for shonclash

One unified ability framework, owned in the repo, no external loaders.

### Target layout

```
src/ReplicatedStorage/Modules/Shared/Combat/
  AbilityRegistry.luau        (id → {data, handler, kind})
  AbilityData/                (data tables, one file per ability — Sasuke_Chidori, Sanji_DiableJambe, Hellflame_Move1, …)
    Sasuke/
      Chidori.luau
      ...
    Hellflame/
      Move1.luau
      ...

src/ServerScriptService/Combat/
  AbilityDispatcher.luau      (single entry point — input event → registry lookup → run handler)
  AbilityHandlers/            (logic, one file per ability — same naming as data tables)
    Sasuke/
      Chidori.luau
    Hellflame/
      Move1.luau
  ChargeStateMachine.luau     (shared Charge/Release state — used by any Chargeable handler)
  Damage.luau                 (renamed/refactored DamageAPI; single authoritative damage call)
```

### Unified handler contract

Every ability handler exports one function with one signature, regardless of source:

```
function(ctx) -> success: bool
  ctx fields:
    Player, Character
    Input            ("Begin" | "End" | "Tap" | "Held")
    ChargeMs         (set if Input == "End" and ability is Chargeable)
    AbilityId        ("Sasuke/Chidori")
    Data             (the registry's data table for this ability)
    State            (the per-player ChargeStateMachine for this ability)
    Modules          (Shared module table — DamageAPI, StateManager, StatusEffectHandler, Network)
```

The dispatcher (`AbilityDispatcher`) is the only thing that listens to the input remote, runs gates (cooldown, stamina, `StateManager:Can(player, "ability")`), invokes the handler, then handles failure → silent-cooldown vs error feedback.

### Effect replication is centralized

Handlers do **not** call `FireAllClients` directly. They call:

```
Effects.Broadcast(character, abilityId, "Begin" | "Hit" | "End", payload)
```

This wraps the typed `Effects` bridge ([`04-networking.md`](04-networking.md)) so the client always knows when an ability begins and ends, even if the handler forgets to send a custom effect.

### Cooldown + stamina at the framework, not the handler

The dispatcher consults `Data.Cooldown` and `Data.Stamina` before invoking the handler. Handlers never write cooldown — they can extend it (`State:ExtendCooldown(seconds)`) but the default path is automatic.

### Migration order

1. **Build the new framework** alongside the existing systems. Empty `AbilityRegistry`, empty `AbilityDispatcher` — just the substrate.
2. **Pick ONE simple fighting style** (probably Melee — lowest blast radius). Move its data to `AbilityData/Melee/*.luau`, write a single handler per move under `AbilityHandlers/Melee/*.luau`, register them. Wire it up so Melee abilities run through the new dispatcher while everything else stays on the legacy loader.
3. **Compare behavior in Studio** (same damage, same VFX timing, same cooldown). Fix any divergences in the framework, not in per-handler code.
4. **Roll the rest of Fighting Styles through one by one.**
5. **Migrate Hellflame / Hollow1** workspace move scripts onto the same framework. Their `Input`/`Modules` shape maps roughly 1:1; the only translation is the externally-injected helpers (`MoveState`, `Timer.Wait`, `ReplicateMove`) become `ctx.State`, `task.wait`, `Effects.Broadcast`.
6. **Delete the external-loader-dependent code paths.** Workspace move scripts can be moved into the repo proper.

### What this NOT do

- Doesn't rewrite the existing data tables — same fields (`Cooldown`, `Stamina`, `Damage`, `Range`, `Endlag`, `Mastery`, `ActionFlag`, `Chargeable`), just relocated.
- Doesn't rebalance any ability values — pure refactor.
- Doesn't touch the `Damage API`'s internal calculation; just the call signature might shift slightly to take `ctx` directly.

## Related docs

- [`02-state-library.md`](02-state-library.md) — gating, status effects.
- [`04-networking.md`](04-networking.md) — Effects bridge.
- [`05-ui-hud.md`](05-ui-hud.md) — HUD ability bar consumes the new Registry (one source of truth for "what cooldowns exist").
