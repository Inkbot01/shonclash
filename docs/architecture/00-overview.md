# Shonen Clash — Backend Modernization Overview

This directory documents the current backend systems, what's wrong with each, and the target replacement modeled on `Inkbot01/fruit` (Fruit Battlegrounds) — our reference codebase, indexed in Nia.

**Status:** research + architecture only. No implementation has started.

## Reading order

The docs below are ordered from "infrastructure" (everything depends on it) to "feature" (consumers of the infrastructure). Read 01–04 to understand the substrate; 05 and 06 are the consumer layers.

1. [`01-data-layer.md`](01-data-layer.md) — player persistence + replication (ProfileService → ProfileStore + Replica)
2. [`02-state-library.md`](02-state-library.md) — combat states + status effects (instance-folder model → typed StateManager + StatusEffectHandler)
3. [`03-combat-abilities.md`](03-combat-abilities.md) — abilities/moves (two coexisting patterns → one unified registry + dispatcher)
4. [`04-networking.md`](04-networking.md) — gameplay RPC (string-named NetworkStream → typed BridgeNet2 bridges)
5. [`05-ui-hud.md`](05-ui-hud.md) — **active scope.** Manual UI → Faye-driven HUD + in-game UI
6. [`06-round-match.md`](06-round-match.md) — round / match / spawn / kill-credit (scattered GlobalData + RoundSystem → one MatchManager + replicated MatchData)

## Modernization roadmap (high-level)

Per `[[project-shonclash-goal]]`, the user is doing this in waves rather than incrementally patching outdated systems.

| Wave | Scope                                       | Why first                                                                                                                              |
| ---- | ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | **UI/HUD** (Faye)                           | User-requested. Doesn't require backend changes if HUD reads from existing `Player.Data` value-mirror via a thin client data adapter.  |
| 2    | **Data layer** (ProfileStore + Replica)     | Once HUD exists, switching the underlying data layer is invisible to UI — just rewire the adapter.                                     |
| 3    | **Networking** (BridgeNet2)                 | Replace `NetworkStream` incrementally bridge-by-bridge. New code uses BridgeNet2; legacy callsites get migrated as they're touched.    |
| 4    | **State + Status effects**                  | Less risky after networking is typed. Replace the instance-folder model with StateManager + StatusEffectHandler.                       |
| 5    | **Combat / abilities consolidation**        | Most invasive — touches every fighting style. Done last when the substrate is clean.                                                   |
| 6    | **Round / match consolidation**             | MatchManager + replicated MatchData. Hooks back into HUD via the data adapter.                                                         |

Intro UI stays untouched throughout. The user has flagged that explicitly.

## Reference repo

- `Inkbot01/fruit` (Fruit Battlegrounds) is indexed in Nia and bound to this project via `nia.json` (source id `ed6f413c-…`). Display name `fruit`; resolve identifier is `Inkbot01/fruit`.
- **⚠️ Topology mismatch:** Fruit is an open-world FFA. Shonen Clash is round-based PvP. Most fruit patterns transfer at the substrate level (data, networking, state, UI) but **not at the match-flow level** — see [`06-round-match.md`](06-round-match.md).
- Fruit itself has both OLD and NEW data systems coexisting (ProfileService + polling vs ProfileStore + Replica). The user should adopt fruit's NEW path, not duplicate fruit's OLD path that already mirrors shonclash's current setup.

## Conventions used in these docs

- **Current state** describes shonclash today.
- **Problems** are concrete failure modes, not stylistic complaints.
- **Reference pattern** is what fruit does — quoted/cited where possible.
- **Recommended replacement** is the high-level architecture for shonclash; **deliberately not code.** Code goes in the implementation phase, gated on user approval per doc.
- File paths are absolute from the repo root (e.g. `src/ServerScriptService/Core/init.server.luau`).
