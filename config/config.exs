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

import_config "#{config_env()}.exs"
