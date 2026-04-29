# Requirements

Extracted from `wildfire-code-exercise.pdf`.

## Functional requirements

- **Pull wildfire data from ESRI's authoritative feed** — the "USA Current Wildfires" feature, exposed via the ArcGIS REST Feature Server.
- **Use the `incidents` layer only.** The feature also exposes a `perimeters` layer; ignore it for the core deliverable (it's listed under extra credit).
- **Distribute the data over a WebSocket.** Speed of delivery is the priority.
- **Use Bandit** as the WebSocket server.
- **Serve the data in GeoJSON** (or another standard geo format) so any UI client can consume it.
- **Operate in the EPSG:4326 spatial reference system.** Source data should be worked with / served in this reference system to match the rest of the geo-analytical platform.
- **No authentication or authorization** is required — the goal is fastest possible distribution to as many clients as possible.

## Non-functional / operational requirements

- **Configurable Postgres connection.** Default may assume `localhost:5432`, but the host/port should be configurable.
- **Reproducible setup.** A README must contain every step needed to run the project.
- **System dependencies declared via `asdf`** (preferred). Other tooling is acceptable if installation and usage are documented.
- **Docker / docker-compose** may be assumed available, but `asdf`-style declaration is preferred for declaring dependencies.

## Delivery

- **Public VCS repository** is preferred for submission.
- **README** must include all information and steps necessary to run the code.

## Extra credit (optional)

- Perimeter data (the second layer of the feature).
- Packaging and deployment plan.
- Telemetry / monitoring of workload.
- UI to visualize current fires.
- Unit / integration tests.

## Derived requirements (from /gsd-explore session, 2026-04-28)

These elaborate the WebSocket distribution contract beyond what the exercise
prompt specified.

- **Single firehose channel.** All subscribers receive all incident events; no
  per-incident or geo-filtered topics in the initial scope.
- **Subscriber identity via UUID.** Server issues a UUID on first connect;
  subscribers may present it on subsequent connects to identify themselves.
- **Cursor-based replay.** Subscribers may include a `since=<event_id>`
  parameter on connect to receive all events with `id > since` before joining
  the live tail. Cursor is the monotonic `incident_events.id` (`bigint`).
- **Event envelope format.** Each event is a JSON object with fields:
  `event_id` (bigint), `type` (`created` | `updated` | `closed`),
  `occurred_at` (ISO 8601), `irwin_id` (string), `feature` (GeoJSON Feature
  in EPSG:4326).
- **Event types and triggers.**
  - `created` — incident seen for the first time.
  - `updated` — existing incident's `ModifiedOnDateTime_dt` advanced.
  - `closed` — `FireOutDateTime_dt` transitions from null to non-null.
- **`occurred_at` source.** `ModifiedOnDateTime_dt` for `created`/`updated`,
  `FireOutDateTime_dt` for `closed`.
- **Configurable poll cadence.** Both incremental poll interval and full-list
  reconciliation interval must be configurable (`config.exs` for compile-time
  defaults, `runtime.exs` for prod overrides).
- **GeoJSON conversion at ingest time.** ArcGIS query parameters request
  `outSR=4326`; conversion to GeoJSON happens before persistence so
  subscribers receive 4326 GeoJSON without runtime transformation.

## Contact

Email Christopher Coté with questions or concerns.
