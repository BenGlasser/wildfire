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
    baseURL = Application.get_env(:wildfire, :base_url, "http://localhost:4000")
    menu = %{ # TODO: create actual json schemas for these https://json-schema.org/
      menu: [
        %{name: "Incidents",
          topic: "incidents",
          endpoint: "#{baseURL}/ws/incidents",
          description: "Real-time updates on wildfire incidents, including new reports, status changes, and resolved cases.",
          events: [
            %{name: "Initial Load", key: "init", description: "Initial load of all active incidents when the client connects."},
            %{name: "New Incident", key: "created", description: "Triggered when a new wildfire incident is reported."},
            %{name: "Status Update", key: "updated", description: "Triggered when the status of an existing incident changes (e.g., from 'active' to 'contained')."},
            %{name: "Incident Resolved", key: "resolved", description: "Triggered when an incident is marked as resolved."}
          ]},

        %{name: "Telemetry",
          stream: "telemetry",
          endpoint: "#{baseURL}/ws/telemetry",
          description: "Real-time updates on telemetry data.",
          events: [
            %{name: "Connection Count", description: "Updates on the number of active WebSocket connections."}
          ]
        }
      ]}
    {:push, {:text, JSON.encode!(menu)}, %{}}
  end

  defp do_init(:incidents, %{"offset" => offset_str}) do
    case parse_offset(offset_str) do
      {:ok, offset} ->
        messages =
          from(e in IncidentEvents,
            where: e.id >= ^offset,
            order_by: [asc: e.id],
            select: e.event
          )
          |> Repo.all()
          |> Enum.map(fn event -> {:text, Jason.encode!(event)} end)

        {:push, messages, %{}}

      :error ->
        do_init(:incidents, %{})
    end
  end

  defp do_init(:incidents, _params) do
    features =
      Repo.all(Incident)
      |> Enum.map(& &1.feature)

    json = Jason.encode!(%{init: features})
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
