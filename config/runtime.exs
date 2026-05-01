import Config

if database_host = System.get_env("DATABASE_HOST") do
  config :wildfire, Wildfire.Repo, hostname: database_host
end

if config_env() == :prod do
  config :wildfire, Wildfire.Repo,
    database: System.get_env("DATABASE_NAME", "wildfire_prod"),
    username: System.get_env("DATABASE_USER", "postgres"),
    password: System.get_env("DATABASE_PASSWORD", "postgres"),
    hostname: System.get_env("DATABASE_HOST", "localhost"),
    port: String.to_integer(System.get_env("DATABASE_PORT", "5432"))
end
