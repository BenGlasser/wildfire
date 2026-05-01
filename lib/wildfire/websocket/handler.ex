defmodule Wildfire.WebSocket.Handler do
  @behaviour WebSock

  alias Wildfire.Repo
  alias Wildfire.Incident

  @impl true
  def init(stream) do
    Wildfire.WebSocket.Manager.subscribe(stream)
    do_init(stream)
  end

  # RECEIVE #############################################

  @impl true
  def handle_in({"ping", _ops}, state) do
    {:push, {:text, "pong"}, state}
  end

  def handle_in(_message, state) do
    {:ok, state}
  end

  # BROADCAST ############################################

  @impl true
  def handle_info({:incidents_changed, %{changed_incidents: features}}, state) do
    json = Jason.encode!(features)
    {:push, {:text, json}, state}
  end

  def handle_info({:telemetry_event, msg}, state) do
    json = Jason.encode!(msg)
    {:push, {:text, json}, state}
  end

  def handle_info(_msg, state) do
    {:ok, state}
  end

  # INITIALIZERS #########################################

  defp do_init(:root) do
    {:push, {:text, "I am Groot! 🪾"}, %{}}
  end

  defp do_init(:incidents) do
    features =
      Repo.all(Incident)
      |> Enum.map(& &1.feature)

    json = Jason.encode!(features)
    {:push, {:text, json}, %{}}
  end

  defp do_init(:telemetry) do
    connections = Registry.lookup(Wildfire.WebSocket.Manager, :telemetry)
    {:push, {:text, "#{length(connections)}"}, %{}}
  end

end
