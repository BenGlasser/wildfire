# Wildfire

Real-time wildfire incident monitor that polls ESRI ArcGIS and pushes GeoJSON to WebSocket clients.

## Prerequisites

- [asdf](https://asdf-vm.com/) with the Elixir and Erlang plugins installed
- Versions are pinned in `.tool-versions`: Elixir 1.19.5-otp-28, Erlang 28.5
- PostgreSQL running on localhost:5432

## Setup

```bash
asdf install
mix deps.get
mix ecto.create && mix ecto.migrate
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

## Running

```bash
mix run --no-halt
```

This starts the OTP supervision tree, which:

1. Connects to PostgreSQL via Ecto
2. Begins polling ESRI ArcGIS for active wildfire incidents
3. Serves a WebSocket endpoint on port 4000

## Connecting

```bash
websocat ws://localhost:4000/ws
```

On connect, all stored incidents are sent as GeoJSON. Changed incidents are pushed automatically after each poll cycle.

## Testing

```bash
mix test
```
