defmodule Wildfire.WebSocket.Routes do
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
