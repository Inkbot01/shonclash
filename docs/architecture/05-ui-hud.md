# 05 — UI / HUD (Active Scope)

This is the immediate work the user has scoped. Everything else in `docs/architecture/` is foundational context; **this doc drives the next deliverables**.

## Current state

### What's in the synced tree
- `default.project.json` maps **only** `ReplicatedStorage`, `ServerScriptService`, and `Workspace`. There is **no `StarterGui` mapping and no `StarterPlayerScripts` mapping.** The HUDs both live in Studio, outside Rojo sync.
- The only HUD-adjacent code in the repo:
  - `src/ServerScriptService/StatisticsHUD Data Retriever.server.luau` — server helper exposing `DistributedGameTime` via the `StatisticsHUD Remotes` folder. Minimal.
  - `src/ReplicatedStorage/Modules/Client/UIEffects.luau` — click effect renderer (not HUD).
  - `src/ReplicatedStorage/Modules/Client/Overheads.luau` — overhead nameplates (not HUD).
- **No UI framework.** No Roact, no Fusion, no Faye.

### Two HUDs exist in Studio (verified via MCP, 2026-05-23)

**OLD HUD — `game.ReplicatedStorage.PrimaryGui.HUD`** (legacy, being replaced)
- ScreenGui in `PrimaryGui` Folder (not in StarterGui, manually copied to PlayerGui by some controller — likely PrimaryGui = "the runtime UI library" pattern).
- Contains a `HUDController` LocalScript with the actual data wiring code. This is the canonical reference for how shonclash data sources connect to UI:
  ```
  Humanoid.HealthChanged         → Profile.Health.Back.Bar (TweenSize) + AmountHP label
  States.Stamina.CurrentStamina  → Profile.Stamina.Back.Bar (TweenSize) + AmountSTM label
  States.Stamina.MaxStamina      → (same path)
  Data.Ability.Changed           → triggers updateLevel
  Data.Mastery[Ability].MasteryLevel/MasteryExperience.Changed → Profile.EXP.Back.Bar + Level text
  ModePoints.Changed             → Profile.Mode.Back.Bar (OUT of v1)
  GlobalData.RoundTimer.Changed  → TimeFrame.Timer.Text (Global.SecondsToHMS)
  Player.CharacterAdded          → reconnect all of the above
  ```
- Widget structure: `MainFrame { Health, Stamina, EXP, Mode }` + `TimeFrame { Timer }`. Has Stamina + Mode + Timer that the NEW HUD does not.

**NEW HUD — `game.StarterGui.HUD`** (the design we target)
- ScreenGui in StarterGui (auto-clones to every PlayerGui at character spawn).
- Architecture **mirrors fruit's HUD exactly**: `Gui` Frame contains `Menu` (panels) + `Screen` (live HUD).
- **`Screen` children (live widgets):**
  - `Display` — Health (Bar + value), Exp (Bar + Lv. + progress + Title + MoneyLabel), Buttons (toolbar — INV/STATS/TRADE/ALLY/STORE/SETTS, 6 nav buttons)
  - `Quest` — quest tracker (Buttons + Frame entries, UIListLayout)
  - `Safezone` — "SAFEZONE" label + icon (visible in safe areas)
  - `Track` — boss/objective tracker (multiple Frames + Billboard, UIListLayout)
  - `BossHealth` — boss health bar + name labels
- **`Menu` children (panels — hidden until toolbar button pressed):**
  - Ally, Settings, Trading, Stats, Inventory, Titles, Storage, Artifact

### Mismatch between NEW HUD design and v1 widget list

| V1 requirement (resolved) | NEW HUD has it? | Notes |
| --- | --- | --- |
| HP bar | ✅ | `Display.Health` (Bar, Outline, value label) |
| Stamina bar | ❌ | NOT in NEW HUD design — needs to be added |
| Ability bar (variable 1-6 slots) | ❌ | NOT in NEW HUD design — needs to be added |
| Round timer + phase | ❌ | NOT in NEW HUD design — needs to be added |
| Hit feedback (damage numbers) | ❌ | NOT in NEW HUD design — needs to be added |
| Knocked overlay | ❌ | NOT in NEW HUD design — needs to be added |
| Settings panel | ✅ | `Menu.Settings` exists, contents unknown |

The NEW HUD also includes widgets **outside v1 scope**: Quest, Safezone, Track, BossHealth, plus the full Menu suite (Ally/Trading/Stats/Inventory/Titles/Storage/Artifact). Per user direction, those stay manual/Studio for v1 and we wire only the v1 subset.

### Loading model (current)
StarterGui.HUD auto-clones into every player's PlayerGui at character spawn. `ResetOnSpawn` not yet checked — if true, the HUD wipes on every respawn (bad for Faye controller binding). Needs to be set to false OR the HUD needs to live in ReplicatedStorage + be cloned once on player join (per user's note about "modify the way it loads").

### What HUD-relevant data is already exposed
By the existing backend (and what the HUD will need to render):

| Source                                            | Field(s)                                  | Used for                          |
| ------------------------------------------------- | ----------------------------------------- | --------------------------------- |
| `Humanoid`                                        | `Health`, `MaxHealth`                     | HP bar                            |
| `Player.States.Stamina`                           | `CurrentStamina`, `MaxStamina`            | Stamina bar                       |
| `Player.Data` (instance mirror of ProfileData)    | `ModePoints`, `MaxModePoints`             | Transformation gauge              |
| `Player.Data`                                     | `Ability`                                 | Active fighting style label       |
| `Player.Data` + `Database.Abilities`              | (lookup per ability)                      | Ability bar slot data             |
| `DebounceAPI`                                     | cooldown timestamps                       | Ability bar cooldown swirl        |
| `ReplicatedStorage.GlobalData.VotingTimer`        | NumberValue                               | Round phase / countdown           |
| `ReplicatedStorage.GlobalData.RoundTimer`         | NumberValue                               | Match countdown                   |
| `RoundSystem.Players[playerName]`                 | `{Kills, Deaths, Points}`                 | Scoreboard                        |
| `StateLibrary.CombatLog` / `LastAttackedBy`       | (state metadata)                          | Kill feed credit                  |
| `StateLibrary` various                            | `Knocked`, `Stunned`, `Blocking`          | Status indicators                 |

### `leaderstats`
Created ad-hoc in `src/ServerScriptService/Core/init.server.luau` with `ModePoints` / `MaxModePoints` NumberValues. The leaderboard (`Leaderboard.server.luau`) reads from `Player.Data`.

## Problems

1. **HUD code is not in the synced tree.** Any UI changes the user makes in Studio aren't version-controlled. Any code we write in the repo to drive UI has no obvious home.
2. **No UI framework, no reactive binding.** Every state-change update has to be hand-wired with `:GetPropertyChangedSignal` / connection cleanup. UI code becomes connection-bookkeeping code.
3. **Data sources are scattered** (Humanoid vs. `Player.States` vs. `Player.Data` vs. `GlobalData`). The HUD has no single API; each widget has to know the right source.
4. **`Player.Data` is a moving target.** Per [`01-data-layer.md`](01-data-layer.md), we're replacing the instance mirror with `PlayerDataClient`. The HUD shouldn't be wired in a way that makes that swap painful.
5. **Faye is not in the repo.** `FAYE.MD` documents the framework but the source isn't present under `src/`. It needs to be vendored before any HUD code runs.

## fruit reference pattern

Fruit *also* uses Faye and has a fully-built HUD. Confirmed via Nia:

- **Location:** `StarterGui/HUD` ScreenGui (synced via Rojo).
- **Architecture:** one root Faye `Thread` per session, owns all sub-widgets. Two top-level Frames inside the ScreenGui: `Gui` (menu/panels) and `Screen` (live HUD).
- **Sub-modules under `ReplicatedStorage/Modules/Client/HUD/`:**
  - `Display.luau` — health + exp + level
  - `Toolbar.luau` — menu nav buttons (Settings, Stats, Inventory, Titles, Storage, Ally, Artifact, Trading)
  - `Stats.luau`, `Inventory.luau`, `Titles.luau`, `Settings.luau`, `Storage.luau`, `Ally.luau`, `Artifact.luau`, `Quest.luau`, `BossHealth.luau`, `Track.luau`, `Safezone.luau`
- **Bootstrap:** `StarterPlayerScripts/HUDController.client.luau` calls the HUD module's `:Init()`.
- **Data binding:**
  - Imports `PlayerDataClient` from `ReplicatedStorage.Modules.Client.PlayerDataClient`.
  - `PlayerDataClient.OnReady()` resolves once the Replica has streamed in initial state.
  - Per-widget: `Data.Bind(Thread, "path.to.field", default)` returns a Faye `Value` mirrored from PlayerDataClient. Subscribes to `OnSet(path, fn)` to push updates back into the `Value`.
  - For Humanoid-sourced data (live health), widgets connect `humanoid:GetPropertyChangedSignal("Health")` directly into a Faye `Value`.
- **Instance properties bind to Values via Faye:**
  ```lua
  Thread:Configure(barInstance)({
      Size = Thread:Animation(healthFillValue, Animation.HealthBarFill),
  })
  ```

## Recommended HUD/UI architecture for shonclash

### Concrete widget set (what to actually build)

Based on the data sources above, the v1 HUD needs:

| Widget                | Bound to                                                          | Notes                                                                                          |
| --------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **HP bar**            | `Humanoid.Health / Humanoid.MaxHealth`                            | Direct property bind, no replication concern                                                  |
| **Stamina bar**       | `Player.States.Stamina.CurrentStamina / MaxStamina`               | Bind via `Thread:InstancePropertySync` or new PlayerDataClient                                 |
| ~~**Mode gauge**~~    | ~~`Player.Data.ModePoints / MaxModePoints`~~                      | **OUT of v1.** No mode/transformation system exists yet. Revisit if/when one is added.        |
| **Ability bar**       | `Player.Data.Ability` (style) + `Database.Abilities` + cooldowns  | **Variable slot count (1–6) per fighting style** — read from new `AbilityRegistry`. Each slot shows: icon, keybind from `KeybindManager`, cooldown swirl, stamina cost, name on hover. |
| **Round timer**       | `GlobalData.VotingTimer` / `RoundTimer`                           | Phase-aware (Voting → Active → End)                                                            |
| **Scoreboard**        | `RoundSystem.Players[*]` (kills/deaths/points)                    | Toggleable (Tab key by convention). Per-player rows.                                          |
| **Kill feed**         | `CombatLog` events (need a small event stream)                    | Bottom-right "X killed Y" rolling list                                                         |
| **Hit feedback**      | `DamageAPI` outgoing fires (need a damage-dealt signal)           | Damage numbers, hit confirmation                                                              |
| **Knocked overlay**   | `StateManager` Knocked signal                                     | Big overlay "DOWNED" + bleedout timer if applicable                                            |
| **Status indicators** | `StateManager` event bus (Stunned, Blocking)                      | Small icon strip near HP bar                                                                  |
| **Notify toast**      | `Bridges.Notify` (server-pushed messages)                         | Top-center fade in/out                                                                        |
| **Map vote UI**       | `MatchPhase == "VOTING"` + map list                               | Only visible during Voting phase                                                              |

### Where to put it

```
default.project.json:
  Add "StarterGui": { "$path": "src/StarterGui" } to the tree.
  Add "StarterPlayer": { ... "StarterPlayerScripts": { "$path": "src/StarterPlayerScripts" } } to the tree.

src/StarterGui/
  HUD/
    init.meta.json   (class = "ScreenGui", ResetOnSpawn = false)
    Gui.meta.json    (class = "Frame" — menu container)
    Screen.meta.json (class = "Frame" — live HUD container)

src/StarterPlayerScripts/
  HUDController.client.luau   (entry point — requires the HUD module, calls Init)

src/ReplicatedStorage/Modules/Client/HUD/
  init.luau                      (HUD root Thread, mounts sub-widgets)
  Display.luau                   (HP + Stamina + level/exp bar group)
  AbilityBar.luau                (4 keybind slots)
  ModeGauge.luau                 (transformation meter)
  RoundTimer.luau                (phase + countdown)
  Scoreboard.luau                (toggleable kills/deaths/points)
  KillFeed.luau                  (rolling event list)
  HitFeedback.luau               (damage numbers)
  KnockedOverlay.luau            (downed state)
  StatusStrip.luau               (Stunned/Blocking icons)
  NotifyToast.luau               (server-pushed messages)
  MapVote.luau                   (during voting phase)
  Data.luau                      (Data.Bind(Thread, path, default) helper — abstracts PlayerDataClient vs Player.Data fallback)
  Anim.luau                      (shared FayeInfos table — HoverInfo, AppearInfo, BarFill, etc.)
```

### Data adapter layer (`HUD/Data.luau`)

This is the **single point** where the HUD reads from the rest of the system. Today it falls back to reading `Player.Data` value instances; tomorrow it proxies to `PlayerDataClient`. Switching is one file.

```
Data.Bind(Thread, "ModePoints", 0)            -> Faye Value mirrored from PlayerData
Data.HumanoidValue(Thread, "Health", 100)     -> Faye Value mirrored from LocalPlayer.Character.Humanoid.Health
Data.StateValue(Thread, "Knocked", false)     -> Faye Value mirrored from StateManager (today: Player.States/Knocked)
Data.GlobalValue(Thread, "VotingTimer", 0)    -> Faye Value mirrored from GlobalData
```

The widgets only know about `Data.luau`. They don't know that today it reads instances and tomorrow it reads Replica streams.

### What needs to exist BEFORE writing widget code

1. **Faye vendored** into `src/ReplicatedStorage/Modules/Shared/Faye/` (Wally or copy). `FAYE.MD` already specifies the API surface.
2. **`default.project.json` updated** to map `StarterGui` + `StarterPlayerScripts`. Run `lune run scripts/add-meta.luau` after.
3. **`HUD/Data.luau` adapter built first** (without any widgets). Test by writing a one-frame "hello world" HUD that reads `Humanoid.Health` and renders a number. Confirms Faye + meta-files + Rojo sync all work end-to-end.
4. **`HUD/Anim.luau` constants file** (from `FAYE.MD`'s `FayeInfos` reference).

### Recommended build order

1. **Substrate** — vendor Faye, add StarterGui/StarterPlayerScripts mappings, build `Data.luau` adapter, write throwaway hello-world HUD. **Verify the loop works in Studio.**
2. **Display** (HP + Stamina) — the highest-value, lowest-risk widget. Direct Humanoid property binding is the simplest possible Faye use.
3. **Ability bar** — second-highest value. Reads `Player.Data.Ability` + `Database.Abilities` + per-ability cooldowns. **Will surface gaps** in how cooldowns are exposed (currently `DebounceAPI` is opaque to the client — see [`03-combat-abilities.md`](03-combat-abilities.md) for the registry plan).
4. **Round timer + map vote** — needs `GlobalData.VotingTimer` and the eventual `Bridges.MatchPhase` ([`06-round-match.md`](06-round-match.md)).
5. **Mode gauge, scoreboard, kill feed, hit feedback** — flesh out.
6. **Status indicators, knocked overlay, notify toast** — polish.

### What this NOT do

- Doesn't touch intro UI. Per the user's scope, intro stays in Studio (or wherever it lives) untouched.
- Doesn't migrate the data layer first. The `Data.luau` adapter is the seam — it lets the HUD ship before [`01-data-layer.md`](01-data-layer.md) is done.
- Doesn't introduce TextPlus until a widget actually needs animated rich text. `FAYE.MD` documents it but it's a separate dependency.

## Resolved decisions (2026-05-23)

- **Ability bar layout — variable, per-ability.** Each fighting style declares its own ability count (1–6 slots depending on the style). HUD reads slot count from the new `AbilityRegistry` ([`03-combat-abilities.md`](03-combat-abilities.md)) and renders dynamically. No hardcoded slot grid.
- **HUD visibility — hidden until first spawn.** Intro UI owns the screen until the `Spawn` remote fires successfully for the first time. On successful spawn the intro hides and the HUD reveals (with an entry animation). The HUD does NOT respond to match-phase changes for visibility — once it's up, it stays up; phase-specific overlays (voting prompt, "Round Over") layer on top.
- **Input scope — PC + Mobile (touch).** All widgets must be touch-friendly: minimum 44px hit targets, ability bar usable from a right-thumb arc, no hover-only affordances (every hover state must have a long-press equivalent). Gamepad is parked for now.
- **No mode gauge in v1.** Mode/transformation system not in scope. Removed from widget list and roadmap. Will revisit when/if a mode system is added.
- **HUD scope — Live HUD + Settings panel only.** Faye owns: HP, Stamina, Ability bar, Round timer, Hit feedback, Knocked overlay (the 6 live widgets) **plus** a Settings panel. Fighting-style picker is **NOT** in HUD scope — the existing intro UI already handles style selection and fires the Spawn flow. Inventory, Quests, Titles, Storage, Trading, Stats stay manual / in Studio for now.
- **V1 widget set (6 live + 1 menu):** HP bar, Stamina bar, Ability bar, Round timer, Hit feedback (damage numbers), Knocked overlay, Settings panel.
- **Faye vendoring — Wally install.** Add Wally to `rokit.toml` (it isn't there today), add `wally.toml` declaring Faye as a dep, run `wally install`. Packages land under a gitignored `Packages/` folder per Wally convention. This also enables vendoring BridgeNet2, ProfileStore, and Replica later via the same path.
- **Mobile parked for v1.5.** PC only for v1 (mouse + keyboard). Ability bar layout: bottom-center horizontal. The earlier "PC + Mobile (touch right-thumb arc)" decision is REVERSED — mobile is dropped from this wave. Mobile right-thumb arc layout returns in a v1.5 wave once core HUD ships.
- **Widget construction split — hybrid.** User designs in Studio: **Stamina bar + Ability bar** (added as new Frames under `StarterGui.HUD.Gui.Screen.Display` or sibling). I build via Faye `Thread:Create` programmatically: **Round timer + Hit feedback + Knocked overlay** (no Studio design needed; they appear/disappear dynamically). The 2 user-designed widgets get Faye controllers that bind to the existing Frames by name. The 3 programmatic widgets get inserted into `Screen` at runtime by the controller.
- **HUD loading — StarterGui + ResetOnSpawn=false + controller in StarterPlayerScripts.** Keep `HUD` ScreenGui in `game.StarterGui` (auto-clones into every PlayerGui at character spawn). Flip `ResetOnSpawn=false` so the HUD persists across respawns. Faye controller lives at `src/StarterPlayerScripts/HUDController.client.luau`. `default.project.json` adds StarterGui + StarterPlayerScripts mappings; the HUD design lives under `src/StarterGui/HUD/` (synced both ways — design changes go through Rojo).
- **Wave 1 scope — v1 subset only.** Quest, Safezone, Track, BossHealth, Exp/Money/Title bar, and the full Menu suite (Ally/Trading/Stats/Inventory/Titles/Storage/Artifact) all **stay static / unwired** for v1. Only the 7 v1 widgets get Faye controllers. The static widgets remain in the HUD design untouched — they just don't update from the new framework yet.

## Out of v1 (parked, not deleted from this doc — see widget table below for what gets built later)

Scoreboard, Kill feed, Status indicators (Stunned/Blocking), Notify toast, Map vote UI, Mode gauge.

## Open questions (still need user input before implementation)

1. **Knocked overlay semantics:** Is "Knocked" a death screen (you're dead, respawn timer ticks) or a downed-but-revivable state (teammate can pick you up)?
2. **HUD theme direction:** Single neutral aesthetic across all widgets, or per-fighting-style accent colors (e.g. Sasuke = blue lightning palette, Endeavor = orange flame)?
3. **Settings panel scope:** What settings need to exist in v1? (Master volume / music vs SFX / camera FOV / motion blur toggle / hit-flash intensity / mobile sensitivity / keybind rebinding / …?)
4. **Map vote UX (parked, will surface when MatchManager wave starts):** Three buttons with vote counts? Hover to preview? Auto-vote if AFK?

## Related docs

- [`01-data-layer.md`](01-data-layer.md) — `PlayerDataClient` is the data source the HUD will eventually use.
- [`02-state-library.md`](02-state-library.md) — `StateManager` event bus drives the status strip + knocked overlay.
- [`03-combat-abilities.md`](03-combat-abilities.md) — ability bar reads from the new `AbilityRegistry` for slot data + cooldowns.
- [`04-networking.md`](04-networking.md) — `Notify`, `MatchPhase`, `Effects` bridges drive HUD events.
- [`06-round-match.md`](06-round-match.md) — round timer + scoreboard subscribe to `MatchData`.
