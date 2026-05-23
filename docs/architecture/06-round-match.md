# 06 — Round / Match / Spawn / Kill-Credit

## Current state

Shonen Clash is a **round-based PvP arena**. State is fragmented across several modules that don't share a contract.

### Round / match flow
Owned primarily by `src/ServerScriptService/Core/Mechanics/Round System.luau`.

- **Phases (implicit, timer-driven):**
  1. **Voting** — `ReplicatedStorage.GlobalData.VotingTimer > 0`. Map vote open. Players cannot spawn.
  2. **Active** — `RoundTimer > 0`. Map loaded into `workspace.World.Maps`. Players can spawn.
  3. **End → reset** — once `RoundTimer == 0`, players are respawned, stats cleared, voting timer restarts.
- **Durations (current):** voting = 15s, round = 400s.
- **Phase transitions:** a server-side coroutine ticks both timers. Phase change is *implicit* from timer values; there's no `PhaseChanged` signal.

### Map voting
- `RoundSystem.MapVotes = {[mapName] = count}`.
- Maps available: `"Hueco Mundo"`, `"Hyperbolic Time Chamber"`, `"Cell Arena"`. Live under `ReplicatedStorage.Maps`.
- At `VotingTimer == 0`: highest-vote map is moved (`:Clone()` + reparent? or `:Reparent`?) into `workspace.World.Maps`. The previous map is unloaded.
- No UI in the synced tree validates votes — invalid map names silently ignored.

### Spawn flow
`Spawn` RemoteEvent handler in `src/ServerScriptService/Core/init.server.luau`:

1. Reject if `GlobalData.VotingTimer > 0`.
2. Reject if `_G.GetData(Player).Ability == ""` (no fighting style selected).
3. Otherwise `Player:LoadCharacter()`.
4. After load, weld equipped outfit morphs from `ReplicatedStorage.Morphs[Outfit]`.

### Kill-credit
On `Player.CharacterRemoving`:
1. `RoundSystem.IncrementData(Player, "Deaths", 1)` — round-scoped stats.
2. `CombatLog.LastAttackedBy` (StateLibrary metadata) checked.
3. If valid attacker: `RoundSystem.IncrementData(Killer, "Points", 100)` + `Kills += 1`.
4. ProfileData (`_G.GetData(Killer).Kills`) **separately** incremented elsewhere (CharacterInitialization or per-fighting-style death-hook — fragmented).

### Storage of round stats
- `RoundSystem.Players[Player.Name] = {Kills, Deaths, Points}` — in-memory, server-process-only.
- Cleared on round end (`RoundSystem.ClearData`).
- **Not persisted.** Per-round stats die with the round; only the cumulative `ProfileData.Kills` survives.

### BOSS SYSTEM
`src/ServerScriptService/BOSS SYSTEM/` is a separate PvE flow. Time-based, independent of round phase. Out of scope for this doc.

## Problems

1. **No canonical phase.** "What phase are we in?" is `if VotingTimer > 0 then "voting" elseif RoundTimer > 0 then "active" else "transitioning"`. Every consumer reimplements this check.
2. **`GlobalData` is a Folder with NumberValues.** Replicates fine, but there's no schema — adding a new field is "create another NumberValue" with no central registry. Type-unsafe.
3. **No PhaseChanged signal.** Clients (and HUD) must poll `VotingTimer.Changed` / `RoundTimer.Changed` and infer phase from the value. Spurious updates fire mid-phase.
4. **Spawn validation is fragile.** Reads `Data.Ability == ""` — a load-order bug (Spawn fires before ProfileData loaded) reads nil, type-errors, kicks the player.
5. **Kill-credit is double-tracked.** `RoundSystem.IncrementData(Killer, "Kills", 1)` AND `_G.GetData(Killer).Kills += 1` happen in different places. A future refactor that touches one but not the other silently desyncs the round scoreboard from the persistent stat.
6. **In-memory `RoundSystem.Players` doesn't survive server restart.** A server crash mid-round wipes the leaderboard.
7. **Map voting has no client-visible feedback.** No UI in the repo. Vote tallies aren't replicated; clients can't see who's winning the vote.
8. **Round end has no celebratory beat.** No "winner" determination, no MVP, no podium — round just ends. (May be intentional MVP for now; flagged as future work.)
9. **Map loading is silent.** `:Reparent` happens; there's no "Loading…" signal. Players see an empty world for the load duration.

## fruit reference pattern

⚠️ **Topology mismatch.** Fruit Battlegrounds is an **open-world FFA** — no rounds, no voting, no discrete matches. Spawn is per-player on choice of island via `PlayerData.Stats.Spawn`. Death triggers immediate respawn at the same/different island. No round end condition.

This means fruit's match-flow code is **not directly applicable to shonclash**. What IS portable:

- **Kill-credit pattern.** Fruit transfers bounty from victim → attacker on death using `CombatLog`-style attacker attribution. Single-source-of-truth: kill credit happens once, in one place.
- **PlayerData-driven spawn.** Spawn location reads from a single PlayerData field (`Stats.Spawn`). Validation is "is the field set?" — same shape as shonclash's `Data.Ability == ""` check.
- **No instance-mirror for transient game state.** Fruit doesn't use a `GlobalData` folder. State machines emit signals; clients subscribe.

Shonclash should **keep rounds** but adopt fruit's "one canonical state, signal-emitting, no instance folder" pattern.

## Recommended replacement for shonclash

### Target: one `MatchManager`, one replicated `MatchData`, signal-emitting

```
src/ServerScriptService/Match/
  MatchManager.luau          (server state machine — VOTING, LOADING, ACTIVE, ENDED phases; owns timer; emits PhaseChanged)
  MapLibrary.luau            (map definitions: name, model path, spawn points, theme)
  KillCredit.luau            (single entry point — increments both round + ProfileData stats)

src/ReplicatedStorage/MatchData/   (Folder synced via Rojo)
  init.meta.json             (class = "Folder")
  CurrentPhase.meta.json     (class = "StringValue", default "VOTING")
  TimeRemaining.meta.json    (class = "NumberValue")
  CurrentMap.meta.json       (class = "StringValue")
  RoundNumber.meta.json      (class = "IntValue")
  PlayerStats/               (Folder, one child Folder per player at runtime — {Kills, Deaths, Points})
```

### Phases (explicit)

```
VOTING   → players can vote, cannot spawn
LOADING  → vote tallied, map loading, players blocked
ACTIVE   → map loaded, players can spawn, round timer ticking
ENDED    → end-of-round beat (1-3s "Round Over"), then transition back to VOTING
```

Transitions are driven by `MatchManager:Transition(newPhase)`. Always emits a `PhaseChanged(oldPhase, newPhase)` signal (on the server) and writes to `MatchData.CurrentPhase` (replicated to clients).

### Signals vs polling

Clients subscribe once:

```
MatchData.CurrentPhase:GetPropertyChangedSignal("Value"):Connect(fn)
```

…or, after [`04-networking.md`](04-networking.md), to `Bridges.MatchPhase`:

```
Bridges.MatchPhase:OnClientEvent(function(payload) ... end)
```

`payload = { phase = "VOTING", timeRemaining = 15, currentMap = "Hueco Mundo", roundNumber = 7 }`.

### Spawn validation

```
function MatchManager.CanSpawn(player) -> (canSpawn: bool, reason: string?)
  if CurrentPhase ~= "ACTIVE" then return false, "match-not-active" end
  if not DataAccess.Get(player, "Ability") then return false, "no-ability-selected" end
  return true
end
```

The `Spawn` bridge (BridgeNet2) calls `MatchManager.CanSpawn(player)` before `Player:LoadCharacter()`. Failure reason returns to client → toast notification.

### Kill credit — single source of truth

```
KillCredit.Award(victim, attacker, source)
  -- increments MatchData.PlayerStats[attacker] (round-scoped)
  -- increments DataAccess.Get(attacker, "Kills") (persistent)
  -- emits KillCredited signal for kill feed, achievements, etc.
  -- one call site, one place to instrument
```

All current `RoundSystem.IncrementData(killer, "Kills", 1)` and `_G.GetData(killer).Kills += 1` get rewritten to `KillCredit.Award(victim, attacker, source)`. The `CharacterRemoving` handler in `Core/init.server.luau` becomes one function call.

### Map vote replication

`MatchData.MapVotes/<MapName>` IntValues, one per available map. Updated on every vote. HUD reads them directly for the live vote-count UI.

### Migration order

1. **Build `MatchData` folder** in `src/ReplicatedStorage/MatchData/`. Update `default.project.json` if needed (it already covers ReplicatedStorage).
2. **Build `MatchManager` skeleton** with `PhaseChanged` signal + phase enum. Initial state = VOTING. Don't wire it up yet.
3. **Migrate the existing timer loop** from `Round System.luau` into `MatchManager`. Both write to `MatchData.TimeRemaining` and `MatchData.CurrentPhase`. Existing consumers reading `GlobalData.VotingTimer` continue to work because `GlobalData` is also updated as a transitional shim.
4. **Build `KillCredit.Award`**. Replace all dual-incrementing kill-credit code with single calls.
5. **Build `MatchManager.CanSpawn`**. The `Spawn` RemoteEvent handler in `Core/init.server.luau` becomes a one-liner: `if MatchManager.CanSpawn(player) then player:LoadCharacter() ...`.
6. **Map loading observability** — `MatchManager:LoadMap(name)` updates `MatchData.CurrentPhase = "LOADING"` for the duration. HUD can show "Loading…" overlay.
7. **Wire HUD** — `RoundTimer.luau` widget subscribes to `MatchData.CurrentPhase` + `TimeRemaining`. Map vote UI subscribes to `MatchData.MapVotes`.
8. **Delete `GlobalData.VotingTimer` / `GlobalData.RoundTimer`** once nothing references them.

### What this NOT do

- Doesn't change round duration or voting duration — pure refactor of the state-management layer.
- Doesn't add win conditions (last-man-standing, score limit). That's a feature request, not a modernization.
- Doesn't touch the BOSS SYSTEM — it's a separate flow.
- Doesn't replace the spawn → `LoadCharacter` → outfit-weld chain inside `Core/init.server.luau` other than the validation prefix.

## Resolved decisions (2026-05-23)

- **Round stats stay ephemeral.** No persistence to ProfileData. RoundSystem stats clear on round end (current behavior preserved). MatchData replicates them in-flight; nothing survives past round end. Persistent stats live in DataAccess only (cumulative Kills, etc.).

## Open questions (still need user input)

1. **End-of-round beat.** Want a "winner" screen / MVP highlight (top fragger over the round)? Or instant transition to voting?
2. **Map list curation.** Are "Hueco Mundo", "Hyperbolic Time Chamber", "Cell Arena" the v1 list, or is the map library growing?
3. **Spawn point selection.** Currently all spawn points in a map are equivalent? Random selection? Team-aware (if teams are added)?

## Related docs

- [`01-data-layer.md`](01-data-layer.md) — KillCredit writes to DataAccess (persistent stats).
- [`04-networking.md`](04-networking.md) — `MatchPhase` bridge replaces `GlobalData` polling.
- [`05-ui-hud.md`](05-ui-hud.md) — RoundTimer, Scoreboard, MapVote widgets all subscribe to `MatchData`.
