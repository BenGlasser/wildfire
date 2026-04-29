# wildfire2

## What This Is

A backend-only Elixir service that pulls live wildfire incident data from ESRI's
authoritative "USA Current Wildfires" feed and broadcasts it to all connected
clients over a single Bandit-served WebSocket as EPSG:4326 GeoJSON. Built as a
hands-on WebSocket exercise — Phoenix/LiveView are deliberately excluded so the
WebSocket plumbing is exposed, not abstracted away.

## Core Value

A connected WebSocket client reliably receives every wildfire incident
event (created/updated/closed) as a 4326 GeoJSON envelope, with the lowest
practical latency and an optional cursor replay for late joiners.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. -->

- [ ] Pull incidents from the ESRI ArcGIS REST Feature Server "USA Current Wildfires" feed (incidents layer only)
- [ ] Persist incident state and an append-only event log in Postgres (via Ecto)
- [ ] Detect created / updated / closed transitions and append events
- [ ] Serve a single WebSocket endpoint via Bandit at `ws://0.0.0.0:4000/ws`
- [ ] Broadcast each event as a JSON envelope `{event_id, type, occurred_at, irwin_id, feature}` with `feature` as 4326 GeoJSON
- [ ] Issue a UUID to each new subscriber on connect; accept a returning UUID for identity
- [ ] Honor `?since=<event_id>` to replay events with `id > since` before joining the live tail
- [ ] Make Postgres connection (host/port/user/pass/db) configurable via runtime.exs/env
- [ ] Make poll cadences configurable (default: incremental 30s, full reconcile 5m)
- [ ] Provide a README with every step needed to clone → run → connect a client
- [ ] Declare runtime versions via `.tool-versions` (asdf)

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Phoenix / LiveView / Plug.Cowboy — defeats the point of this exercise (hands-on WebSocket)
- Authentication / authorization — exercise spec explicitly excludes; goal is fastest fan-out
- Per-client filtering or per-incident topics — single firehose channel only
- Perimeter layer ingestion — extra credit, not in v1
- Frontend / UI — backend-only deliverable
- Packaging / deployment manifests, telemetry dashboards — extra credit, not in v1

## Context

- ESRI feed: `https://services3.arcgis.com/T4QMspbfLg3qTGWY/ArcGIS/rest/services/USA_Wildfires_v1/FeatureServer/0` (incidents layer). Query with `outSR=4326&f=geojson` so conversion lives at ingest.
- Identity in the source data: `IrwinID` (stable across updates).
- Lifecycle markers in the source: `ModifiedOnDateTime_dt` advances on update; `FireOutDateTime_dt` flips from null → non-null when a fire closes.
- Replay cursor is `incident_events.id` (`bigint`, monotonic).
- Local Postgres is assumed available at `localhost:5432` with `postgres/postgres`.
- This is a code exercise — minimal LOC is a goal, but tests are welcome where they cut manual verification.
- Contact for spec questions: Christopher Coté.

## Constraints

- **Tech stack**: Elixir + OTP + Bandit + Ecto. No Phoenix, no LiveView, no Plug.Cowboy.
- **Spatial reference**: All persisted/served geometry is EPSG:4326. ArcGIS query enforces `outSR=4326` so the runtime never reprojects.
- **Distribution model**: Single firehose WebSocket; speed prioritized over filtering.
- **No auth**: WebSocket is open to all callers.
- **Dependency declaration**: `asdf` (`.tool-versions`) is preferred for Erlang/Elixir; Postgres is BYO and configurable.
- **Code minimality**: Prefer the smallest correct implementation; reach for the standard library and small fundamental libs over abstractions.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Bandit as the only HTTP/WS server | Required by the exercise; keeps stack thin | — Pending |
| No Phoenix/LiveView | Goal is hands-on WebSocket, not framework familiarity | — Pending |
| Ecto + Postgres for incident state and event log | Need durability + monotonic event id for `since=` replay | — Pending |
| GeoJSON conversion at ingest (`outSR=4326&f=geojson`) | Avoid runtime reprojection; subscribers consume directly | — Pending |
| Single firehose channel (no per-incident topics) | Matches "fastest possible distribution" mandate | — Pending |
| Default WS endpoint `0.0.0.0:4000/ws` | Familiar dev port, single path, runtime-overridable | — Pending |
| Default poll cadences 30s / 5m | Live-feel without hammering ESRI; runtime-overridable | — Pending |
| App name `wildfire2` | Matches repo directory | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-29 after initialization*
