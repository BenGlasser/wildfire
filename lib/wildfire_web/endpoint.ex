defmodule WildfireWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :wildfire

  @session_options [
    store: :cookie,
    key: "_wildfire_key",
    signing_salt: "wildfireSalt0",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Static,
    at: "/",
    from: :wildfire,
    gzip: false,
    only: WildfireWeb.static_paths()
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)

  plug(WildfireWeb.Router)
end
