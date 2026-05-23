# 01 — Player Data Layer

## Current state

### Active path — ProfileService + instance mirror

Setup: `src/ServerScriptService/_initiate/init.server.luau` plus modules under `_initiate/Modules/Data/`.

- **Library:** ProfileService.
- **Profile key:** `SHONENCLASH_0006` (bump on schema change).
- **Schema:** `_initiate/Modules/Data/ProfileData.luau` — flat + nested fields (Ability, Bounty, Gem, Kills, Mastery, Inventory, DailyQuests, …).
- **Replication boundary:** `LoadValuesToInstanceFromTable` mirrors the profile table into a folder of `*Value` instances under `Player.Data`. Server holds the source-of-truth table; client reads the instance mirror. On player leave (or every 40s), `LoadTableFromInstanceValues` flushes the mirror back into the profile table.
- **Canonical accessor:** `_G.GetData(Player)` returns the live profile table. Set up in `_initiate/init.server.luau`.
- **Cross-player reads:** `Remotes.GetData` RemoteFunction returns a profile *view* for arbitrary userIds. Backed by `StoredPlayersCache` (40s TTL).

### Legacy / parallel path — `NetSync` + `PlayerData` (inactive but present)

- `src/Workspace/NetSync/init.luau` — Weeve-authored metatable-based replication layer with `Public`/`Private` filters and a separate `GetData` RemoteFunction. Never initialized by the active boot path.
- `src/Workspace/PlayerData/init.luau` — wrapper that pairs `NetSync` with its own DataStore loop. Also never initialized.
- Both still ship in the repo and are easy to invoke accidentally.

## Problems

1. **Two parallel systems with overlapping responsibility.** The legacy `NetSync` / `PlayerData` modules duplicate ProfileService's job and could be wired in by mistake. Cognitive load + risk.
2. **Bidirectional instance mirroring loses data on unclean shutdown.** Client reads `Player.Data` and could mutate it (replication-side, exploits aside). Flush happens every 40s — a crash between flushes loses ≤40s of progress.
3. **No typed schema.** `ProfileData.luau` is a plain Lua table. Nothing prevents drift between server and client expectations of structure.
4. **40s `StoredPlayersCache` is server-lifetime-only.** Cross-player view requests after a server restart go straight to DataStore with no warm cache.
5. **`Leaderboard.server.luau` reads from the `Player.Data` instance folder.** Tight coupling to the mirroring choice — if we replace mirroring with snapshot-push, the leaderboard breaks unless rewritten.
6. **Schema-bump cost is high.** ProfileService key change (`SHONENCLASH_0006`) wipes every profile. Reconciliation logic (additive vs destructive) isn't documented.

## fruit reference pattern

Fruit has **the same legacy split** in its repo (so we have a clear "before / after" inside one codebase):

### OLD path (do not copy)
- `ProfileService` + a polling loop running every **0.8s** (`Replicate.luau`) that mirrors data into instances.
- `_G.DataFunctions` / `_G.Profiles` globals.

### NEW path (target architecture)
- **ProfileStore** — drop-in successor to ProfileService by the same author. Session-locking, async session start, automatic release on leave.
  - DataStore key: `"PlayerData" + storeVersion`. Profile key: `"Player_" + userId`. Cleanly versioned.
- **Replica** — event-driven client replication. Server creates a `Replica` for the player; client subscribes via `Replica:OnChange(path, callback)`. No polling, no instance mirror.
- **DataAccess module** — single clean API on top of ProfileStore + Replica (`Get(player, path)`, `Set(player, path, value)`, `Subscribe(path, fn)`, etc.). Server-side.
- **PlayerDataClient module** — client-side façade. `PlayerDataClient.OnReady()`, `PlayerDataClient.GetData(path)`, `PlayerDataClient.OnSet(path, callback)`. Used by every UI module.
- Lives under `ServerScriptService.Data` (server) and `ReplicatedStorage.Modules.Client.PlayerDataClient` (client).

## Recommended replacement for shonclash

### Target architecture

```
src/ServerScriptService/Data/
  ProfileStore.luau            (vendored — MadStudioRoblox/ProfileStore)
  ReplicaService.luau          (vendored — MadStudioRoblox/ReplicaService) 
  ProfileTemplate.luau         (schema — moved out of _initiate/Modules/Data/ProfileData.luau)
  ProfileHandler.luau          (session lifecycle: load on join, release on leave)
  DataAccess.luau              (server API: Get/Set/Subscribe/Increment)
  Leaderstats.luau             (derives leaderstats from DataAccess, NOT Player.Data folder)

src/ReplicatedStorage/Modules/Client/
  PlayerDataClient.luau        (client API: OnReady / GetData(path) / OnSet(path, fn))
```

### Replication boundary changes

- **Drop the `Player.Data` instance folder.** Every read currently going through `Player.Data.X.Value` becomes `PlayerDataClient.GetData("X")` or a Replica `:OnChange("X")` subscription.
- **Cross-player views (`Remotes.GetData`) stay** but are served from a server-side cache atop ProfileStore (`Profile:ViewAsync` for offline players), not from the live profile table.
- **Leaderstats** derive from `DataAccess` instead of reading the instance mirror.

### Migration order

1. **Vendor ProfileStore + ReplicaService** (Wally, or copy-in to `src/ReplicatedStorage/Packages/`). Add a `ProfileTemplate.luau` that mirrors current `ProfileData.luau` structure 1:1.
2. **Build `ProfileHandler` + `DataAccess` server-side** alongside the existing ProfileService bootstrap. Don't remove ProfileService yet — they coexist on different profile keys (`SHONENCLASH_0006_legacy` vs `SHONENCLASH_0006`).
3. **Build `PlayerDataClient`** that proxies to the new Replica. Initially have it fall back to reading `Player.Data` if no replica exists, so old client code keeps working during migration.
4. **Migrate consumers one at a time.** Each consumer (HUD widget, Leaderstats, GetData RemoteFunction, etc.) flips from `Player.Data` reads to `PlayerDataClient`/`DataAccess` reads.
5. **Delete `Workspace/NetSync` + `Workspace/PlayerData`** the moment nothing references them.
6. **Drop the instance-mirror flush loop** from `_initiate/init.server.luau` once all consumers are on the new path.
7. **Bump profile key once** at cutover (e.g. `SHONENCLASH_0100`) and run `Profile:Reconcile()` for backwards compatibility.

### Calling out

- **The HUD wave should NOT block on this.** The HUD can read `Player.Data` instance values via `Thread:InstancePropertySync` initially — see [`05-ui-hud.md`](05-ui-hud.md). When the data layer flips, the HUD changes from `InstancePropertySync` to `PlayerDataClient.OnSet` and stays otherwise identical.
- **ProfileStore vs ProfileService** — same author, ProfileStore is newer and the recommended path. Migration is mostly a rename + session-start API change.

## Related docs

- [`04-networking.md`](04-networking.md) — BridgeNet2 carries the Replica change events.
- [`05-ui-hud.md`](05-ui-hud.md) — `PlayerDataClient` is the HUD's primary input.
- [`06-round-match.md`](06-round-match.md) — `RoundSystem.Players` round-stats should also live in DataAccess after this, not in-memory.
