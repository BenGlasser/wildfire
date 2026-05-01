import Config

config :wildfire, WildfireWeb.Endpoint,
  server: true,
  code_reloader: true,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:wildfire, ~w(--sourcemap=inline --watch)]}
  ]
