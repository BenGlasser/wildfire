import Config

config :wildfire, Wildfire.Repo,
  database: "wildfire_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox

config :wildfire, :esri_req_options, [plug: {Req.Test, Wildfire.ESRI}]
config :wildfire, :http_port, 4001
config :wildfire, :poll_interval, 86_400_000
