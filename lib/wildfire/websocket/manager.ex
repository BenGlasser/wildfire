defmodule Wildfire.WebSocket.Manager do
  @streams [:incidents, :telemetry, :root]

  def subscribe do
    Enum.each(@streams, &subscribe/1)
  end

  def subscribe(stream) when stream in @streams do
    Registry.register(Wildfire.WebSocket.Manager, stream, [])
  end

  def subscribe(stream) do
    raise ArgumentError, "Invalid stream: #{inspect(stream)}. Valid streams are: #{@streams}"
  end

  def broadcast(stream, msg) do
    case stream do
      :root ->
        IO.inspect("HERE!")
        Registry.dispatch(Wildfire.WebSocket.Manager, :incidents, fn entries ->
          for {pid, _} <- entries, do: send(pid, {:incidents_changed, msg})
        end)

      :incidents ->
        Registry.dispatch(Wildfire.WebSocket.Manager, :incidents, fn entries ->
          for {pid, _} <- entries, do: send(pid, {:incidents_changed, msg})
        end)

      :telemetry ->
        Registry.dispatch(Wildfire.WebSocket.Manager, :telemetry, fn entries ->
          for {pid, _} <- entries, do: send(pid, {:telemetry_event, msg})
        end)
    end
  end
end
