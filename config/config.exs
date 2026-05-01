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

import_config "#{config_env()}.exs"
