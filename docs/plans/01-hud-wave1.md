# Plan 01 — Wave 1 HUD Implementation

Scope: build the v1 HUD on top of the existing `game.StarterGui.HUD` design, using Faye for reactive binding. PC only. 7 widgets total (HP, Stamina, Ability bar, Round timer, Hit feedback, Knocked overlay, Settings).

Source of truth for decisions driving this plan: [`../architecture/05-ui-hud.md`](../architecture/05-ui-hud.md) §"Resolved decisions".

## Pre-flight (gated — pause for user sign-off before any of this lands)

Each pre-flight item changes shared project config. Stopping after each to confirm sanity.

### P1. Add Wally to rokit.toml

- Edit `rokit.toml` to add `wally = "UpliftGames/wally@0.3.2"` (or latest stable).
- Run `rokit install` — installs Wally CLI alongside Rojo + Lune.
- **Verification:** `wally --version` returns a version string.
- **Blast radius:** local toolchain only. Zero impact on game runtime.

### P2. Add wally.toml + install Faye

- Create `wally.toml` at repo root with:
  - `[package]` name `shonclash`, version `0.1.0`, realm `shared`, registry `https://github.com/UpliftGames/wally-index`.
  - `[dependencies]` Faye (need to confirm exact package name — likely `mountaindouw/faye` or similar). If Wally registry doesn't have Faye, fall back to **copy fruit's vendored Faye** via Nia (`nia repos read Inkbot01/fruit ReplicatedStorage/Modules/Shared/Faye/...`) and commit it directly into `src/ReplicatedStorage/Modules/Shared/Faye/`.
- Add `Packages/` to `.gitignore` (Wally packages should not be committed).
- Run `wally install`. Packages land under `Packages/`.
- Add a Rojo mapping for `Packages/` in `default.project.json` so they end up in `ReplicatedStorage.Packages` at runtime.
- **Verification:** `Packages/Faye/` exists (or `src/ReplicatedStorage/Modules/Shared/Faye/` exists). Studio sees Faye accessible via `require(ReplicatedStorage.Packages.Faye)` or `require(ReplicatedStorage.Modules.Shared.Faye)`.
- **Blast radius:** new dependency in repo. Doesn't affect existing code.

### P3. Map StarterGui + StarterPlayerScripts in default.project.json

Update `default.project.json` to add:
```json
"StarterGui": { "$path": "src/StarterGui" },
"StarterPlayer": {
  "StarterPlayerScripts": { "$path": "src/StarterPlayerScripts" }
}
```

- Create empty `src/StarterGui/` and `src/StarterPlayerScripts/` directories.
- **Important:** must run `lune run scripts/add-meta.luau` to add `init.meta.json` files (per CLAUDE.md invariant — every dir needs the `ignoreUnknownInstances: true` meta).
- **Verification:** `rojo serve` syncs without errors. Studio shows existing HUD in StarterGui unchanged.
- **Blast radius:** **MEDIUM.** First time Rojo syncs StarterGui from filesystem, any UI that exists only in Studio (not in `src/StarterGui/`) gets wiped from the live Studio tree. **MUST run Rojo syncback first** to capture the existing HUD design INTO `src/StarterGui/HUD/`, then serve normally.

### P4. Syncback existing StarterGui.HUD into src/

Per CLAUDE.md syncback workflow:

1. Save Studio place to `~/Documents/shonclash.rbxl`.
2. Run `lune run scripts/dedupe.luau ~/Documents/shonclash.rbxl ~/Documents/shonclash-deduped.rbxl`.
3. Use Rojo's syncback feature (or manually serialize) to write `StarterGui.HUD` into `src/StarterGui/HUD/`.
4. **Verification:** `src/StarterGui/HUD/init.meta.json` exists (ClassName: ScreenGui, ResetOnSpawn: false). The Gui/Menu/Screen subtree is present in `src/StarterGui/HUD/Gui/`.
5. **Blast radius:** medium. First time the HUD design is committed to disk. Worth a checkpoint commit before any further changes.

### P5. Flip ResetOnSpawn=false on the HUD ScreenGui

- Edit `src/StarterGui/HUD/init.meta.json` to add `Properties.ResetOnSpawn: false`.
- **Verification:** in Studio, character respawn no longer wipes HUD instances.
- **Blast radius:** small. HUD now persists; the OLD `HUDController` LocalScript in `PrimaryGui.HUD` may not re-fire on respawn since it relies on the HUD being fresh each spawn. Need to verify the OLD HUD path still works OR is being intentionally retired.

### P6. Sign-off gate

Stop. User reviews the changes from P1-P5. Confirms Studio still loads HUD correctly. Confirms repo builds (`rojo build -o shonclash.rbxlx` succeeds). Once green, proceed to Step 1.

---

## Step 1 — Data adapter (`HUD/Data.luau`)

**Goal:** centralize every HUD read behind one module so widgets don't know whether data comes from instances, the OLD path, or (eventually) PlayerDataClient.

**File:** `src/ReplicatedStorage/Modules/Client/HUD/Data.luau` (or move to `Modules/Shared/HUD/Data.luau` if both client and server need it — likely client-only).

**API surface:**
```
Data.HumanoidValue(Thread, propertyName, default)
  -- Returns a Faye Value bound to LocalPlayer.Character.Humanoid[propertyName].
  -- Reconnects on CharacterAdded. Auto-cleans with Thread.

Data.StateValue(Thread, stateName, valueChild, default)
  -- Returns a Faye Value bound to LocalPlayer.States.<stateName>.<valueChild>.
  -- Example: Data.StateValue(thread, "Stamina", "CurrentStamina", 0)

Data.PlayerDataValue(Thread, path, default)
  -- Returns a Faye Value bound to a Player.Data nested value by dotted path.
  -- Example: Data.PlayerDataValue(thread, "Ability", "") or "Mastery.Sasuke.MasteryLevel".

Data.GlobalValue(Thread, valueName, default)
  -- Returns a Faye Value bound to ReplicatedStorage.GlobalData.<valueName>.

Data.LeaderstatValue(Thread, statName, default)
  -- Returns a Faye Value bound to LocalPlayer.leaderstats.<statName>.
```

**Internals:** uses `Thread:InstancePropertySync` for property-backed values, `Thread:Connect(.Changed, ...)` for nested folder paths. Reconnects on `LocalPlayer.CharacterAdded` for Humanoid-bound values.

**Verification:** unit test in a throwaway LocalScript — `print(Data.HumanoidValue(thread, "Health", 100):Get())` reports current health. Confirm reconnect on respawn.

**Blast radius:** zero — new file, no existing code touched.

---

## Step 2 — HUD bootstrap (`StarterPlayerScripts/HUDController.client.luau`)

**Goal:** mount the Faye Thread, register widget controllers, hide HUD until first spawn, reveal on spawn.

**Pseudocode shape:**
```
local Faye = require(ReplicatedStorage.Packages.Faye)   -- or .Modules.Shared.Faye
local Thread = Faye.new()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")

HUD.Enabled = false

-- listen for first successful spawn
ReplicatedStorage.Remotes.Spawn.OnClientEvent:Connect(function(success)
    if success and not revealed then
        HUD.Enabled = true
        -- mount widget controllers
        require(HealthBar)(Thread, HUD.Gui.Screen.Display.Health)
        require(StaminaBar)(Thread, HUD.Gui.Screen.Display.Stamina)  -- gated on user designing it
        require(AbilityBar)(Thread, HUD.Gui.Screen)                  -- gated on user designing it
        require(RoundTimer)(Thread, HUD.Gui.Screen)                  -- programmatic insertion
        require(HitFeedback)(Thread, HUD.Gui.Screen)                 -- programmatic insertion
        require(KnockedOverlay)(Thread, HUD.Gui)                     -- programmatic insertion
        require(SettingsPanel)(Thread, HUD.Gui.Menu.Settings)
    end
end)
```

**Open issue:** the `Spawn` RemoteEvent in current code is server→client OneClient firing? Need to verify the signal direction. If Spawn is currently just client→server (request), we need a server→client `SpawnSuccess` confirmation. Will add this as a tiny server-side hook.

**Verification:** Studio playtest — start in intro UI, no HUD visible. Trigger Spawn, HUD reveals with entry animation.

**Blast radius:** small. New LocalScript. Touches the Spawn flow only to listen for success.

---

## Step 3 — HP bar (`HUD/HealthBar.luau`)

**Goal:** smallest-possible widget that proves the whole pipeline (data adapter + Faye + bound instance).

**File:** `src/ReplicatedStorage/Modules/Client/HUD/HealthBar.luau`.

**Wiring:**
```
return function(Thread, HealthFrame)
    local Health = Data.HumanoidValue(Thread, "Health", 100)
    local MaxHealth = Data.HumanoidValue(Thread, "MaxHealth", 100)

    -- bind bar size
    Thread:Configure(HealthFrame.Bar)({
        Size = Thread:Animation(
            Thread:Do(function(Grab)
                local h, m = Grab(Health), Grab(MaxHealth)
                return UDim2.new(h / m, 0, 1, 0)
            end),
            FayeInfos.QuickSine
        ),
    })

    -- bind label (existing TextLabel)
    Thread:Configure(HealthFrame.TextLabel)({
        Text = Thread:Do(function(Grab)
            return string.format("%d / %d", math.floor(Grab(Health)), math.floor(Grab(MaxHealth)))
        end),
    })
end
```

**Verification:** Studio playtest — take damage, bar shrinks with QuickSine ease, label updates immediately. Take damage to 0, bar reaches 0%.

**Blast radius:** small. New file. Reads-only from Humanoid.

---

## Step 4 — User design task (gated)

**User work, not Claude work.** User adds two new Frames inside `StarterGui.HUD.Gui.Screen.Display` in Studio:

1. **`Stamina`** Frame — same internal structure as `Health` (Outline, Bar, Lines, TextLabel(s)). Sized & positioned visually below Health.
2. **`AbilityBar`** Frame in `Screen` (sibling of Display) — bottom-center horizontal. Contains a template `Slot` Frame (icon ImageLabel, keybind TextLabel, cooldown swirl ImageLabel with semi-transparent overlay, optional name TextLabel) that the controller will clone for each ability slot.

When done, user syncs back (`rbxl → dedupe → src/StarterGui/HUD/`), commits, signals me to continue.

**Why gated:** widget controllers can't bind to Frames that don't exist yet. Forcing the design step keeps visual control with the user.

---

## Step 5 — Stamina bar (`HUD/StaminaBar.luau`)

Same shape as HP bar. Binds `Data.StateValue(Thread, "Stamina", "CurrentStamina", 0)` and `MaxStamina`. Identical wiring to HealthBar.

**Verification:** Studio playtest — sprint or use stamina-consuming ability, bar updates.

---

## Step 6 — Ability bar (`HUD/AbilityBar.luau`)

**Goal:** dynamic slot count (1-6) per fighting style. Reads ability list from `Player.Data.Ability` → `ReplicatedStorage.Modules.Shared.Database.Abilities[<style>]` → enumerate abilities.

**Wiring:**
```
return function(Thread, ScreenFrame)
    local SlotTemplate = ScreenFrame.AbilityBar.Slot  -- user-designed template
    SlotTemplate.Visible = false
    SlotTemplate.Parent = nil  -- detach template

    local Ability = Data.PlayerDataValue(Thread, "Ability", "")

    Thread:State(function(Grab, InnerThread, Entity)
        local style = Grab(Ability)
        if style == "" then return end

        local abilities = Database.Abilities[style]
        if not abilities then return end

        for index, abilityData in pairs(abilities) do
            local slot = SlotTemplate:Clone()
            slot.Visible = true
            slot.Parent = ScreenFrame.AbilityBar
            slot.LayoutOrder = index

            -- bind cooldown swirl
            local cooldown = Data.AbilityCooldown(InnerThread, style, abilityData.Name)
            InnerThread:Configure(slot.Cooldown)({ ... })

            -- bind keybind label
            slot.KeybindLabel.Text = KeybindManager.GetKeyFor(style, abilityData.Name)
            slot.NameLabel.Text = abilityData.Name
            slot.Icon.Image = abilityData.IconAsset or ""
        end
    end)
end
```

**Open issue: cooldown source.** Current code uses `DebounceAPI` server-side, opaque to client. For v1, two paths:
- **(A)** Client predicts cooldown from local state (when Ability handler runs, start a client-side timer matching `Data.Cooldown`). Risk: desync.
- **(B)** Add a server-side `AbilityFired` BridgeNet2-style remote that pushes `{ability, cooldownSeconds}` to the client on every successful ability fire. Cleaner, more work.

Recommend **(A)** for v1 to avoid blocking on networking wave. Note as tech debt.

**Verification:** equip a fighting style, fire an ability, slot's cooldown swirl rotates and prevents re-use until timer ends.

---

## Step 7 — Round timer (`HUD/RoundTimer.luau`)

**Programmatic widget.** Inserted into `Screen` by the controller (no Studio design needed).

**Wiring:** binds `GlobalData.VotingTimer` and `GlobalData.RoundTimer`. Derives phase: voting if VotingTimer > 0 else active. Renders top-center: `[VOTING] 0:14` (yellow) or `[ROUND] 6:32` (white).

**Verification:** Studio playtest — voting phase shows yellow countdown, transitions to white round timer.

---

## Step 8 — Hit feedback (`HUD/HitFeedback.luau`)

**Programmatic widget.** Floating damage numbers above target characters when local player deals damage.

**Server hook needed:** `DamageAPI.InflictDamage` needs to fire a `Bridges.HitDealt` (BridgeNet2 once Wave 3 lands; for now, a new RemoteEvent `HitFeedback` in `ReplicatedStorage.Remotes`) to the attacker only, with `{ targetPosition, amount, isCritical }`.

**Client widget:** subscribes to the remote, spawns a TextPlus-styled (`Pop` + `Drop` + Fade) label at the world-space position of the target, lifts upward over 0.6s, removes itself.

**Blast radius:** **small server change** — add one `:FireClient(attacker, payload)` call in DamageAPI after a successful hit. Doesn't affect damage logic.

**Verification:** Studio playtest — hit a dummy, see floating "23" rise and fade.

---

## Step 9 — Knocked overlay (`HUD/KnockedOverlay.luau`)

**Programmatic widget.** Full-screen dim overlay with "DEFEATED" text + respawn countdown.

**Trigger:** subscribes to `Player.States.Knocked.Base:GetPropertyChangedSignal("Value")`. On `true`, fade in overlay + countdown. On `false` or `CharacterAdded`, fade out.

**Decision per [`05-ui-hud.md`](../architecture/05-ui-hud.md):** Knocked = death screen. No revive UI for v1.

**Verification:** Studio playtest — get killed, "DEFEATED" overlay appears with 3-2-1 countdown, fades on respawn.

---

## Step 10 — Settings panel (`HUD/SettingsPanel.luau`)

**Goal:** wire the existing `Menu.Settings` Frame to actually do something.

**v1 settings (from `05-ui-hud.md` resolved):** Audio (master / music / SFX), Graphics (motion blur toggle, hit-flash intensity, particle density). No keybind rebinding for v1.

**Storage:** settings persist to `Player.Data.Settings` (add to `ProfileData.luau` schema with a default subtable). For v1 they read/write through the instance mirror — when ProfileStore + Replica land in Wave 2, the storage path flips automatically through the Data adapter.

**Wiring:** toolbar SETTS button toggles `Menu.Settings.Visible`. Each setting bound to a Value, which writes back to `Player.Data.Settings.X` on change.

**Verification:** open settings, drag master volume slider, music volume drops in real-time. Close + reopen — slider position preserved (instance-mirror persists). Disconnect + reconnect — settings persist (ProfileService persists).

---

## Sign-off gates

The plan pauses for user confirmation at:

1. **After P5** — pre-flight done, repo builds. Last chance to flip the loading model or vendor a different UI framework.
2. **After Step 2** — bootstrap working, HUD reveals on spawn. Validates that the whole loading flip + Faye runtime are happy.
3. **After Step 3** — HP bar working. Validates the Data adapter + Faye binding pattern. Every subsequent widget is a copy of this shape.
4. **After Step 6** — Ability bar working. The most complex widget; if this is OK, the rest are mechanical.
5. **After Step 10** — v1 complete. Demo + decide what's next (Wave 2 data layer? More widgets? Polish pass?).

## Out of scope (for explicit awareness)

- Quest, Safezone, Track, BossHealth widgets — left static, not wired.
- Menu panels other than Settings — not wired.
- Mobile (touch right-thumb arc) — parked for v1.5.
- Mode gauge — backend doesn't exist; out of scope.
- Map vote UI — depends on Wave 6 MatchManager.
- Scoreboard, Kill feed, Status indicators (Stunned/Blocking), Notify toast — listed as v1 in the doc table but deferred to v1.5 because the user-locked "Core combat (7 widgets)" scope was: HP, Stamina, Ability bar, Round timer, Hit feedback, Knocked overlay, Settings. They're tracked in the doc's widget table for later.

## Risks

- **R1.** Wally registry may not have Faye. Mitigation: fall back to vendoring fruit's Faye source via Nia.
- **R2.** Syncback may not perfectly round-trip the HUD design (UDim2 precision, asset ID handling). Mitigation: ship checkpoint commit immediately after P4, before any further changes.
- **R3.** OLD `PrimaryGui.HUD` HUDController may break when `ResetOnSpawn` flips on the NEW HUD. Mitigation: confirm OLD HUD is being retired in this wave (likely yes), or skip P5 until OLD is decommissioned.
- **R4.** Step 6 cooldown predicts client-side, could desync. Tech debt for Wave 3 (networking) — add `AbilityFired` bridge that pushes authoritative cooldown.
- **R5.** Hit feedback needs a small server-side change (Step 8) that touches DamageAPI. Code review carefully — DamageAPI is the security-critical entry point for damage. Single `:FireClient(attacker, ...)` call should not introduce risk, but flag it during review.
