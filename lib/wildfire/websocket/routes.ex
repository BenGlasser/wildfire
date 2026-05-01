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
          var!(conn)
          |> WebSockAdapter.upgrade(Wildfire.WebSocket.Handler, unquote(stream),
            timeout: :infinity
          )
          |> halt()
        end
      end
    end
  end
end
