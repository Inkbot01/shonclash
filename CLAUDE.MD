# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Roblox Luau game (Shonen Clash / `SHONENCLASH_0006` profile key) — round-based PvP arena with anime-style "fighting styles" (Sasuke, Sanji, Endeavor, Whitebeard, Deku, Melee, Dual Katana). Source on disk is synced into Roblox Studio via Rojo; nothing here is a standalone executable.

## Toolchain & Common Commands

Tools are managed by **Rokit** (pinned in `rokit.toml`): Rojo `7.7.0-rc.1`, Lune `0.9.4`. Selene is used as the Luau linter (`selene.toml` declares the Roblox std).

```sh
rokit install                                    # install pinned versions of rojo + lune
rojo serve                                       # live-sync src/ → Studio (default port 34872)
rojo build -o shonclash.rbxlx                    # build place file from src/
rojo sourcemap -o sourcemap.json                 # regenerate for luau-lsp/Roblox-LSP
selene src/                                      # lint
lune run scripts/add-meta.luau                   # regenerate ignoreUnknownInstances meta files
lune run scripts/dedupe.luau <in.rbxl> <out.rbxl> # pre-process a Studio-built rbxl for syncback
```

**Rojo project root:** `default.project.json` maps `src/ReplicatedStorage`, `src/ServerScriptService`, `src/Workspace` to the matching Roblox services. Anything outside those three trees is not synced.

**Meta files:** every directory has an `init.meta.json` and every `.luau` script has a sibling `<name>.meta.json`, all containing `ignoreUnknownInstances: true`. This is required so Studio-added children don't get wiped on sync. After creating new dirs/scripts on disk, run `lune run scripts/add-meta.luau` to keep this invariant.

**Syncback workflow:** Studio → filesystem must go through `scripts/dedupe.luau` first. The script renames duplicate sibling instances (`Foo`, `Foo_2`, `Foo_3`, …) and sanitizes filesystem-illegal characters — Rojo can't map a Roblox tree onto a filesystem otherwise. Default I/O paths are `~/Documents/shonclash.rbxl` → `~/Documents/shonclash-deduped.rbxl`.

## Architecture

### Module loading — `Directory.Import`

`ReplicatedStorage/Directory.luau` is a **name-based module locator**, not a path-based require. It scans every Folder under ReplicatedStorage (Shared) and ServerScriptService (Server) once at startup, then resolves modules by name:

```lua
local Directory = require(ReplicatedStorage.Directory)
local StateLibrary = Directory.Import("StateLibrary", "Shared")
local Database     = Directory.Import("Database",     "Shared")
local DamageAPI    = Directory.Import("Damage API",   "Server")   -- spaces allowed
```

Two consequences:
- **Module names must be globally unique within their environment.** Two `Utility` ModuleScripts in different folders will collide silently — first match wins.
- New top-level Folders need to exist *before* `Directory.luau` runs; it does not re-scan. Existing scripts call `Directory.Import` at require-time, so module load order matters.

For client-side requires, `Server` is `nil` — only `Shared` is available.

### Player data — two parallel systems (legacy + current)

1. **ProfileService (active path)** — `ServerScriptService/_initiate/init.server.luau`. Schema in `_initiate/Modules/Data/ProfileData.luau`. Profile key is `SHONENCLASH_0006` (bump when schema changes). On join, the profile table is mirrored into a `Player.Data` Folder of `*Value` instances via `LoadValuesToInstanceFromTable`; on leave/shutdown, `LoadTableFromInstanceValues` flushes it back. **`_G.GetData(Player)` is the canonical accessor** and is set up by this script. A background coroutine flushes every 40s, and there's a 10s timeout on first read.
2. **NetSync / PlayerData (Weeve, legacy-style)** — `Workspace/NetSync` + `Workspace/PlayerData`. Separate Weeve-authored replication module that maintains `Module.PlayerData[Player]` with per-key Public/Private filters. Coexists with ProfileService; do not assume changes to one propagate to the other.

The `GetData` RemoteFunction (`ReplicatedStorage.Remotes.GetData`) returns profile *views* for arbitrary userIds — used for stat panels / leaderboards. Cached for 40s in `StoredPlayersCache`.

### Server bootstrap — `Core/init.server.luau`

This is the main per-player setup script. On `PlayerAdded` it:
1. `StateLibrary.CreateStates(Player)` — builds the `States` folder from `StatePresets`.
2. Runs `CharacterInitialization` for the initial character and on every `CharacterAdded`.
3. Hooks `CharacterRemoving` for death tracking (Deaths++, CombatLog kill credit, RoundSystem stats).
4. `QuestAPI.GiveDailyQuests`, creates `leaderstats` + ad-hoc `ModePoints`/`MaxModePoints` NumberValues.

`CharacterInitialization` reparents the character to `workspace.World.Entities`, creates `Accessories`/`Swords` folders, loads the toolbar via `ToolSystem`, fires the Endeavor init effect if applicable, and installs a Humanoid `HealthChanged` clamp that triggers a `Knocked` state at HP=1.

Spawning is gated by the `Spawn` RemoteEvent — it refuses while `GlobalData.VotingTimer > 0` or `Data.Ability == ""`, then runs `Player:LoadCharacter()` and welds equipped outfit morphs from `ReplicatedStorage.Morphs[Outfit]`.

### Combat / abilities

For each character there are **two paired files**:
- `ServerScriptService/Core/AbilityAPI/Fighting Styles/<Name>.luau` — server logic (input handlers per ability with `Charge`/`Release` keys, state mutations, hitbox queries, damage dispatch).
- `ReplicatedStorage/Modules/Shared/Database/Abilities/<Name>.luau` — pure data table: `Cooldown`, `Stamina`, `Damage`, `Range`, `Endlag`, `Mastery`, `ActionFlag`, `Chargeable`.

Editing balance values usually means touching only the `Database/Abilities/*` file. Editing behavior means touching the matching `Fighting Styles/*` file (which reads from `Database` at runtime).

Global ability primitives live in `Modules/Shared/Database/Global/` (Combat, Movement) and `KeybindManager` is at the Database root.

### Workspace move scripts (alternate dispatch pattern)

Some characters' moves (e.g. `Workspace/Hellflame/HellflameServerScripts/MOVE1..6.luau`, `AWAKENING.luau`, paired `HellflameClientScripts/*`) follow a different convention — they return a function with signature:

```lua
return function(Character, Input, MoveState, ReplicateMove, Timer, Modules, ClientData, FiredData)
    if MoveState:InCooldown() then return false end
    -- ...
end
```

These are loaded by an external move dispatcher (not present in this repo snapshot — likely a Studio-installed package). When adding new Hellflame-style moves, mirror the existing MOVE# pattern exactly; the dispatcher relies on the return signature and Modules table shape.

### StateLibrary

`Modules/Shared/StateLibrary/` builds a `States` folder per Player from `StatePresets.luau`. Each state has a `Category`: `NormalInteger` (active while `now - Begin >= Duration`), `SpecialInteger` (active while `now - Begin <= Duration`), or `Boolean` (raw `Base.Value`). `ActionFlags` (`Ability`, `Block`) map an action category to the set of states that must all be false for the action to fire — `StateLibrary.IsValidAction(Player, "Ability")` is the gate.

Mutate states with `StateLibrary.ModifyState(Player, StateName, value_or_duration, extraTable?)`. Never write directly to `Player.States` — the comparison methods read `Begin`/`Duration` and the value flows through them.

### Networking — `NetworkStream`

`Modules/Utility/NetworkStream.luau` wraps `ReplicatedStorage.Remotes` and caches every Remote descendant once on require. Three entry points:

- `FireAllClients(Entity, RemoteName, RenderDistance, ...)` — **distance-gated** broadcast. Only players within `RenderDistance` of `Entity.PrimaryPart` receive the event. This is how all combat VFX/SFX should be sent — never bare `:FireAllClients` for spatial effects.
- `FireOneClient(Player, RemoteName, ...)`
- `FireServer(_, RemoteName, ...)` — client → server.

Use `RemoteName` strings, not Instance references. If a Remote is added at runtime, it won't be in the cache — restart the server or extend the module.

### UI framework (Faye + TextPlus)

`FAYE.MD` documents a declarative reactive UI framework (Faye) and a rich-text animation library (TextPlus). **These modules are not currently present in `src/`** — `FAYE.MD` references paths under `src/shared/Modules/Shared/Faye` and `src/shared/Modules/Shared/textplus/` that don't exist. The doc is a forward-looking spec; if/when those modules are added (or installed via Wally into the gitignored `Packages/`), apply the patterns it describes. TextPlus is expected to be reachable as `global.SharedModules["textplus"]`.

## Code Standards

Carried from the previous CLAUDE.md (these are the user's standing preferences):

- SOLID, KISS, DRY, YAGNI — pragmatism wins when they conflict with idiomatic Roblox patterns.
- **No comments** unless they encode a non-obvious *why* (race conditions, exploit mitigations, Roblox quirks). Don't restate what the code does.
- Production-ready: handle edge cases, validate inputs at trust boundaries (RemoteEvents especially — never trust the client), profile hot paths, debounce inputs.
- When refactoring, ship targeted before/after diffs with a one-line reason, not full file rewrites.

**Pre-modification checklist:**
1. Logic — conditionals, loops, race conditions, yields across the wrong frame.
2. Roblox-specific — RemoteEvent surface area, replication boundaries, connection leaks (always `:Disconnect` or use `Maid`/`Janitor`), `:WaitForChild` timeouts, character lifecycle.
3. Performance — Heartbeat work, table allocations in inner loops, missing debounces.
4. Security — server-side validation, no client-trusted damage/state writes, no exploitable RemoteFunction returns.
5. Scalability — hard-coded magic numbers vs. `Database/` data tables, tight coupling to specific characters.

If a request conflicts with these, flag it before implementing.
