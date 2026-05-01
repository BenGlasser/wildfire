defmodule Wildfire.WebSocket.Routes do
  @moduledoc """
    Defines the WebSocket routes for the application.  This module is meant to be `use`d in the main router to inject the necessary routes for WebSocket connections.

    The WebSocket handler is defined in `Wildfire.WebSocket.Handler`, and the manager for broadcasting messages is defined in `Wildfire.WebSocket.Manager`.

    The following routes are defined:
    - `/ws`: Subscribes to the `:root` stream, which currently sends a greeting message and can be used for future root-level events.
    - `/ws/telemetry`: Subscribes to the `:telemetry` stream, which receives telemetry events.
    - `/ws/incidents`: Subscribes to the `:incidents` stream, which receives incident events. It also accepts an optional `offset` query parameter to fetch incident events starting from a specific ID.

    Each route upgrades the connection to a WebSocket and initializes the handler with the appropriate stream and parameters.
  """

  # This is probably a terrible idea but I couldn't help myself.  macros are fun ¯⁠\⁠_⁠(⁠ツ⁠)⁠_⁠/⁠¯

  @streams [
    {"/ws", :root},
    {"/ws/telemetry", :telemetry},
    {"/ws/incidents", :incidents}
  ]

  defmacro __using__(_opts) do
    for {path, stream} <- @streams do
      quote do
        get unquote(path) do
          conn = Plug.Conn.fetch_query_params(var!(conn))
          handler_arg = {unquote(stream), conn.query_params}

          conn
          |> WebSockAdapter.upgrade(Wildfire.WebSocket.Handler, handler_arg, timeout: :infinity)
          |> halt()
        end
      end
    end
  end
end
