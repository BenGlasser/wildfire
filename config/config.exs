import Config

config :wildfire, ecto_repos: [Wildfire.Repo]

config :wildfire, Wildfire.Repo,
  database: "wildfire_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432

config :wildfire, :poll_interval, 30_000
config :wildfire, :esri_req_options, []

config :wildfire, WildfireWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  render_errors: [
    formats: [html: WildfireWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: Wildfire.PubSub,
  live_view: [signing_salt: "wildfireLV0"],
  secret_key_base: "rT8xq3hZk6Lp2WnYbVcJ4eMaQs7fGdHuKj9oRwIyT5BvNxUmCzDlPgErAhSbXi0F"

config :esbuild,
  version: "0.21.5",
  wildfire: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --loader:.png=file --loader:.svg=file),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import_config "#{config_env()}.exs"
