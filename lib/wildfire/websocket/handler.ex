defmodule Wildfire.WebSocket.Handler do
  @behaviour WebSock

  import Ecto.Query

  alias Wildfire.Repo
  alias Wildfire.Data.Schema.Incident
  alias Wildfire.Data.Schema.IncidentEvents

  @impl true
  def init({stream, params}) do
    Wildfire.WebSocket.Manager.subscribe(stream)
    do_init(stream, params)
  end

  def init(stream) when is_atom(stream) do
    init({stream, %{}})
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
  def handle_info({:incidents_changed, event}, state) do
    json = Jason.encode!(event)
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

  defp do_init(:root, _params) do
    {:push, {:text, "I am Groot! 🪾"}, %{}}
  end

  defp do_init(:incidents, %{"offset" => offset_str}) do
    case parse_offset(offset_str) do
      {:ok, offset} ->
        events =
          from(e in IncidentEvents,
            where: e.id >= ^offset,
            order_by: [asc: e.id],
            select: e.event
          )
          |> Repo.all()

        json = Jason.encode!(events)
        {:push, {:text, json}, %{}}

      :error ->
        do_init(:incidents, %{})
    end
  end

  defp do_init(:incidents, _params) do
    features =
      Repo.all(Incident)
      |> Enum.map(& &1.feature)

    json = Jason.encode!(features)
    {:push, {:text, json}, %{}}
  end

  defp do_init(:telemetry, _params) do
    connections = Registry.lookup(Wildfire.WebSocket.Manager, :telemetry)
    {:push, {:text, "#{length(connections)}"}, %{}}
  end

  defp parse_offset(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, ""} when n >= 0 -> {:ok, n}
      _ -> :error
    end
  end

  defp parse_offset(_), do: :error
end
