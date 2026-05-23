# 04 — Networking (Gameplay RPC)

## Current state

### `NetworkStream` — string-keyed remote wrapper
`src/ReplicatedStorage/Modules/Utility/NetworkStream.luau`. Wraps `ReplicatedStorage.Remotes` (a Folder of pre-created RemoteEvents). Three entry points:

- `NetworkStream.FireAllClients(Entity, RemoteName, RenderDistance, ...)` — distance-gated broadcast. Computes `Global.GetNearPlayers(Entity.PrimaryPart.Position, RenderDistance)` per call and fires only to that subset.
- `NetworkStream.FireOneClient(Player, RemoteName, ...)`
- `NetworkStream.FireServer(_, RemoteName, ...)` — client → server. The first arg is unused (a holdover; the module signature is slightly misleading).

Remote lookup is by string name against a cache (`CachedRemotes`) built **once on require**. Any RemoteEvent added to `ReplicatedStorage.Remotes` at runtime is invisible to the wrapper.

### Server-authority
`DamageAPI.InflictDamage` validates: alive check, state validation (Blocking, IFrame, etc.), party-friendly-fire logic. Damage flows only through this server function — clients cannot directly write health. Good.

### Legacy `NetSync` (different layer)
`src/Workspace/NetSync/init.luau` is the data-replication layer used by the inactive legacy `PlayerData` module — orthogonal to `NetworkStream`, which is the gameplay-RPC layer. Covered in [`01-data-layer.md`](01-data-layer.md), not here.

## Problems

1. **No compile-time check on remote names.** A typo (`"Effct"` instead of `"Effect"`) is a silent runtime no-op. No diagnostic, no failure mode.
2. **Runtime-added remotes silently fail.** Any code path that creates a Remote after `NetworkStream` requires (some plugin, late-loaded module) is invisible to the wrapper. The fix is "restart the server", which is fine for development but invisible at runtime.
3. **No typed payloads.** Every fire is `(...args)` — caller and receiver must agree on shape by convention. Refactoring the payload (renaming a field, changing a type) cannot be caught by tooling.
4. **`FireServer`'s unused first arg.** The signature confuses readers and is a footgun for anyone using IDE auto-complete.
5. **`RenderDistance` is recomputed per-call.** Acceptable for occasional broadcasts, but high-frequency particle/effect spam scales poorly — each call walks every player to compute distance. No subscription model.
6. **No request-response.** RemoteFunctions exist for `GetData` but `NetworkStream` doesn't wrap them. Cross-machine queries are bolted on case-by-case.

## fruit reference pattern

Fruit uses **BridgeNet2** (a typed RemoteEvent wrapper by ffrostfall) — ~7 bytes lower per-packet overhead and ~75% lower client-side processing latency than raw RemoteEvents.

Key shape:

- **Static bridge names** declared once (`BridgeNames.luau` or similar) — frozen at module load. Server creates `ServerBridge(name)`; client creates `ClientBridge(name)`. Same enum on both sides, so typos error at require-time, not runtime.
- **Single-arg fires.** `bridge:Fire(player, payload)` where `payload` is one table. Encourages bundling instead of varargs sprawl.
- **Recipient builders.** BridgeNet2 ships `Network.AllPlayers()`, `Network.Except(player)`, `Network.Players({a, b})`, `Network.Single(player)`. Composable.
- **No explicit distance-gating.** Distance filters are a caller concern (fruit games are open-world, not distance-relevant the way an arena is).
- **Custom request-response on top.** Fruit has a `Network.InvokeClient(player, name, payload, timeout)` helper that opens a response-bridge with a `RequestId`, awaits the matching response, returns or times out.
- **Concrete bridges in fruit:** `AbilityAction`, `Effects`, `ServerNotify`, etc. — domain-named, not Remote-named.

```lua
-- Fruit pattern (from Stun Library):
Network.Effects:Fire(Network.AllPlayers(), {
    Ability = "Electro Stun",
    Data = { Target = Player.Character, StunDuration = 2 },
})
```

## Recommended replacement for shonclash

### Library choice
Adopt **BridgeNet2** (Wally: `ffrostfall/bytenet@…` — note: ffrostfall has both BridgeNet2 and ByteNet; pick BridgeNet2 for the established pattern fruit uses).

Alternative: **ByteNet** (same author, schema-typed) — slightly newer, requires more upfront packet definitions. Pick BridgeNet2 unless we want full schema typing.

### Target layout

```
src/ReplicatedStorage/Modules/Shared/Net/
  BridgeNet2/                  (vendored)
  Bridges.luau                 (static bridge name registry — frozen on require)

src/ReplicatedStorage/Modules/Server/Net/
  Network.server.luau          (ServerBridge factories, RequestId helpers)

src/ReplicatedStorage/Modules/Client/Net/
  Network.client.luau          (ClientBridge factories, request-response helpers)
```

### Distance-gating
Because shonclash IS an arena game and distance matters (VFX from across the map shouldn't replicate), keep distance-gating as a **first-class wrapper on top of BridgeNet2**:

```
Network.FireNearby(entity, range, bridge, payload)
```

This wraps `Global.GetNearPlayers` and calls `bridge:Fire(recipients, payload)` once. Centralized, not per-callsite.

### Bridge naming
Domain-named, not Remote-named. Initial set (mirrors current `NetworkStream` traffic):

- `AbilityRequest` — client → server, used by the new `AbilityDispatcher` ([`03-combat-abilities.md`](03-combat-abilities.md))
- `Effects` — server → clients, all visual effect broadcasts
- `Notify` — server → one client, UI notifications
- `Spawn` — client → server (rename from current `Spawn` remote — same purpose)
- `MatchPhase` — server → all clients, round phase transitions ([`06-round-match.md`](06-round-match.md))

### Authority
Unchanged. Damage flows through `DamageAPI` (renamed `Combat.Damage` per `03-combat-abilities.md`). Bridges are pipes; they don't validate, callers do.

### Migration order

1. **Vendor BridgeNet2.** Add to `src/ReplicatedStorage/Modules/Shared/Net/BridgeNet2/`.
2. **Build the `Bridges.luau` registry** with bridge names matching the current `NetworkStream.FireAllClients(_, "Name", _, ...)` callsites — `Effects`, `Notify`, `Ability`, etc.
3. **Create `Network` server + client modules** that expose `Bridges.Effects`, `Bridges.Notify`, etc. and the `Network.FireNearby` helper.
4. **Migrate high-traffic bridges first.** `Effects` is the biggest win (high-frequency, the typed bridge gives concrete bandwidth savings). All callsites of `NetworkStream.FireAllClients(_, "Effect", _, ...)` flip to `Bridges.Effects:Fire(Network.FireNearby(...))` (or the wrapper).
5. **Migrate per-domain bridges next** — `Notify`, `Spawn`, `Ability`.
6. **Delete `NetworkStream`** once nothing references it.

### What this is NOT

- Doesn't change the server-authority model — damage stays in `DamageAPI`.
- Doesn't move the `GetData` RemoteFunction yet — that lives in the data layer wave.
- Doesn't introduce ECS, packet schema definitions, or a serializer beyond what BridgeNet2 provides.

## Related docs

- [`01-data-layer.md`](01-data-layer.md) — Replica change events ride on a bridge.
- [`03-combat-abilities.md`](03-combat-abilities.md) — `Effects` bridge is the centralized VFX broadcaster.
- [`06-round-match.md`](06-round-match.md) — `MatchPhase` bridge replaces polling on `GlobalData.VotingTimer`.
