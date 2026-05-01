# Wildfire

Real-time wildfire incident monitor that polls ESRI ArcGIS, persists incident events to PostgreSQL, and pushes GeoJSON updates to WebSocket clients. A small React + Vite UI renders the live map.

## Local Endpoints

When running locally (via `docker compose up` or `mix run --no-halt` + `pnpm --dir ui dev`):

| URL                                                              | What it is                                                                                       |
|------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| [http://localhost:5173](http://localhost:5173)                   | React UI (Vite dev server) — proxies `/ws*` to the Elixir app                                    |
| [http://localhost:4000/test](http://localhost:4000/test)         | Static WebSocket tester page (`priv/static/ws_test.html`)                                        |
| `ws://localhost:4000/ws`                                         | Root stream — greeting/root-level events                                                         |
| `ws://localhost:4000/ws/incidents`                               | Incident stream — initial GeoJSON snapshot, then `created` / `updated` / `resolved` events       |
| `ws://localhost:4000/ws/incidents?offset=<id>`                   | Incident stream replayed from a specific `incident_events.id`                                    |
| `ws://localhost:4000/ws/telemetry`                               | Telemetry stream                                                                                 |

The UI connects through the Vite proxy at `ws://localhost:5173/ws/incidents`, which forwards to the Elixir app on `4000`.

## Prerequisites

Pick one path:

**Docker (recommended)**
- Docker + Docker Compose

**Native**
- [asdf](https://asdf-vm.com/) with Elixir and Erlang plugins (versions pinned in `.tool-versions`: Elixir 1.19.5-otp-28, Erlang 28.5)
- Node + [pnpm](https://pnpm.io/) for the UI
- PostgreSQL running on `localhost:5432`

## Setup & Run

### Docker

```bash
docker compose up
```

This brings up PostgreSQL plus the Elixir app, runs `ecto.create` / `ecto.migrate` on boot, and exposes:
- `4000` — Elixir HTTP + WebSocket server
- `5173` — Vite dev server for the React UI

### Native

```bash
asdf install
mix deps.get
mix ecto.create && mix ecto.migrate
mix run --no-halt
```

In another shell:

```bash
cd ui
pnpm install
pnpm dev
```

## Configuration

In dev and test, the database connection uses static defaults from `config/config.exs` (database `wildfire_dev`, user `postgres`, password `postgres`, host `localhost`, port `5432`).

In prod, the following environment variables are read at startup via `config/runtime.exs`:

| Variable            | Default          |
|---------------------|------------------|
| `DATABASE_NAME`     | `wildfire_prod`  |
| `DATABASE_USER`     | `postgres`       |
| `DATABASE_PASSWORD` | `postgres`       |
| `DATABASE_HOST`     | `localhost`      |
| `DATABASE_PORT`     | `5432`           |

When running under Docker Compose, `DATABASE_HOST` is set to `postgres` (the compose service name).

## What's Running

The OTP supervision tree:

1. Connects to PostgreSQL via Ecto
2. Polls ESRI ArcGIS for active wildfire incidents
3. Persists changes to `incident_events`
4. Serves the WebSocket endpoints listed above on port 4000

On WebSocket connect, all stored incidents are sent as GeoJSON. Changed incidents are pushed automatically after each poll cycle.

## Quick Connect (CLI)

```bash
websocat ws://localhost:4000/ws/incidents
```

## Testing

```bash
mix test
```
