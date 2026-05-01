# Table of Contents

- [Table of Contents](#table-of-contents)
- [Wildfire](#wildfire)
  - [Dependencies](#dependencies)
    - [Elixir and Erlang](#elixir-and-erlang)
    - [Docker](#docker)
    - [Postgres](#postgres)
  - [Building and running things](#building-and-running-things)
    - [The Docker Way...](#the-docker-way)
    - [The Other Way...](#the-other-way)
  - [Connecting](#connecting)
    - [LiveView map](#liveview-map-httplocalhost4002)
    - [WebSocket clients](#websocket-clients)
    - [Built-in tester](#built-in-tester)
    - [Remote IEx shell](#remote-iex-shell)
  - [Configuration](#configuration)
  - [Testing](#testing)
  - [Thoughts](#thoughts)

# Wildfire

Wildfire is a small Elixir service that keeps a real-time eye on active wildfire incidents. It polls the [ESRI ArcGIS](https://www.arcgis.com/) public wildfire feed on a regular interval, persists each incident to PostgreSQL, and pushes the latest [GeoJSON](https://geojson.org/) snapshot to any client subscribed over a WebSocket.

When a client connects, all currently stored incidents are sent down the wire as a single GeoJSON feature collection. After that, every poll cycle that finds new, changed, or resolved incidents pushes a fresh delta to all connected clients, so the front end always reflects what's actively burning right now.

The whole thing runs as a plain OTP application supervised by a single tree — there's a poller, an `Ecto.Repo`, a `Phoenix.PubSub`, and a Bandit/Phoenix endpoint serving the socket on port `4000`.

## Dependencies

- elixir 1.19.5-otp-28
- erlang 28.5
- docker (optional, but recommended)
- postgres 13+ (only if you're going the non-docker route)

### Elixir and Erlang

If you use [`asdf`](https://asdf-vm.com/) with the elixir and erlang plugins, the `.tool-versions` file in the project root pins the right versions. Install them with:

```
asdf install
```

### Docker

Any recent version of `docker` with `compose` baked in will do. If you don't have it, grab it from [docker.com](https://www.docker.com/) or skip to [The Other Way](#the-other-way).

### Postgres

Wildfire needs a Postgres instance somewhere. Docker compose spins one up for you; otherwise you'll need one running locally on port `5432`.

## Building and running things

Clone the repo:

```
git clone https://github.com/BenGlasser/wildfire.git
```

### The Docker Way...

From the project root:

```
docker compose up
```

This builds the image, starts Postgres, runs `mix ecto.create && mix ecto.migrate`, and boots the app on port `4000`. Add `-d` to run detached, and `docker compose down` to tear it all back down.

### The Other Way...

Make sure Postgres is running locally on port `5432` with user `postgres` / password `postgres`. If `psql -h localhost -U postgres` works, you're set.

Then from the project root:

```
mix deps.get && mix ecto.create && mix ecto.migrate && mix run --no-halt
```

The poller logs every 30 seconds and the WebSocket endpoint comes up on port `4000`.

## Connecting

### LiveView map (`http://localhost:4002/`)

The Phoenix Endpoint serves a live, dark-themed D3 canvas map of every active incident at the root URL. Points glow brighter where fires cluster (additive blending), animate in when the poller sees a new incident, and grey-fade out on resolve. Drag to pan, scroll to zoom, hover for detail.

```
mix run --no-halt
# then open http://localhost:4002/
```

The legacy `Plug.Router` and WebSocket endpoints below still run alongside on port `4000`.

### WebSocket clients

The live incident stream is served at `/ws/incidents`. Point your favorite WebSocket client at it — [`websocat`](https://github.com/vi/websocat) is a no-frills option:

```
websocat ws://localhost:4000/ws/incidents
```

On connect, the server sends every stored incident as a single GeoJSON feature collection. After that, any time the poller finds an incident that was created, changed, or resolved, an updated payload is pushed to all connected clients automatically.

> Note: `/ws` itself is the socket mount point — connecting there directly will not stream any data. Use `/ws/incidents`.

### Built-in tester

If you don't feel like installing a WebSocket client, the app ships with a browser-based tester. With the server running, open:

```
http://localhost:4000/ws/test
```

It connects to `/ws/incidents` for you and renders the incoming payloads so you can sanity-check the stream.

### Remote IEx shell

The docker `CMD` boots the app as a named distributed Erlang node, so you can attach a remote `iex` session to poke around the running system. From your host:

```
docker exec -it wildfire iex --name console@127.0.0.1 --cookie wildfire --remsh app@127.0.0.1
```

You'll land in an `iex` shell connected to the live VM with full access to `Wildfire.Repo`, the poller, PubSub, and the rest of the supervision tree. Use `Ctrl+C Ctrl+C` to detach without killing the app.

If you're running without docker, boot with:

```
elixir --name app@127.0.0.1 --cookie wildfire -S mix run --no-halt
```

and then connect from another terminal with the same `iex --remsh` command.

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

## Testing

Run the full test suite with:

```
mix test
```

Individual tests can be run by supplying a file path, `mix test </path/to/test.exs>` or `mix test </path/to/test.exs>:<line-number>`.

If they don't pass for you, all I can say is "_It works on my machine_" ¯\\\_(ツ)\_/¯

## Thoughts

A few things worth coming back to:

1. **Backpressure on the WebSocket push.** Every connected client gets every delta as soon as the poller emits it. With many clients, we'd want to coalesce updates per client and shed load gracefully rather than letting mailboxes grow unbounded.
2. **Smarter diffing.** The poller currently writes incident events for created, changed, and resolved transitions. There's room to be more surgical about what actually counts as a "change" — small float jitter in the geometry shouldn't trigger a push.
3. **Persisted client cursors.** Reconnecting clients re-receive the full feature collection. A cursor or `since` token would let them catch up incrementally.
4. **A real frontend.** Wildfire now ships a LiveView map at `/` (port 4002) that pushes incremental deltas into a D3 canvas — see [LiveView map](#liveview-map-httplocalhost4002). The legacy `/ws/incidents` socket on port 4000 still runs in parallel.
