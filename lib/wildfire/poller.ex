defmodule Wildfire.Poller do
  use GenServer
  require Logger

  import Ecto.Query

  alias Wildfire.Repo
  alias Wildfire.Data.Schema.Incident

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    schedule_poll(0)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:poll, state) do
    try do
      run_poll()
    rescue
      e -> Logger.error("Poll failed: #{inspect(e)}")
    end

    schedule_poll(interval())
    {:noreply, state}
  end

  def run_poll do
    case Wildfire.ESRI.fetch_incidents() do
      {:ok, []} ->
        Logger.info("No incidents fetched")
        :ok

      {:ok, features} ->
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        candidates = Enum.map(features, &build_row(&1, now))
        source_ids = Enum.map(candidates, & &1.source_id)
        polled_source_id_set = MapSet.new(source_ids)

        old_hashes =
          from(i in Incident,
            where: i.source_id in ^source_ids,
            select: {i.source_id, i.feature_hash}
          )
          |> Repo.all()
          |> Map.new()

        all_db_source_ids =
          from(i in Incident, select: i.source_id)
          |> Repo.all()
          |> MapSet.new()

        created =
          Enum.filter(candidates, fn row ->
            not Map.has_key?(old_hashes, row.source_id)
          end)

        changed =
          Enum.filter(candidates, fn row ->
            case Map.fetch(old_hashes, row.source_id) do
              {:ok, hash} -> hash != row.feature_hash
              :error -> false
            end
          end)

        resolved_source_ids =
          all_db_source_ids
          |> MapSet.difference(polled_source_id_set)
          |> MapSet.to_list()

        resolved_features =
          if resolved_source_ids == [] do
            []
          else
            from(i in Incident,
              where: i.source_id in ^resolved_source_ids,
              select: i.feature
            )
            |> Repo.all()
          end

        (created ++ changed)
        |> Enum.chunk_every(500)
        |> Enum.each(fn chunk ->
          Repo.insert_all(Incident, chunk,
            on_conflict: {:replace, [:feature, :feature_hash, :updated_at]},
            conflict_target: :source_id
          )
        end)

        event_rows =
          [
            {:created, Enum.map(created, & &1.feature)},
            {:updated, Enum.map(changed, & &1.feature)},
            {:resolved, resolved_features}
          ]
          |> Enum.reject(fn {_type, features} -> features == [] end)
          |> Enum.map(fn {type, features} ->
            %{type: type, event: %{type => features}}
          end)

        if event_rows != [] do
          Repo.insert_all(Wildfire.Data.Schema.IncidentEvents, event_rows)
        end

        Enum.each(event_rows, fn row ->
          Wildfire.WebSocket.Manager.broadcast(:incidents, row.event)

          Phoenix.PubSub.broadcast(
            Wildfire.PubSub,
            "incidents",
            {:incident_event, row.type, row.event[row.type]}
          )
        end)

        if resolved_source_ids != [] do
          from(i in Incident, where: i.source_id in ^resolved_source_ids)
          |> Repo.delete_all()
        end

        Logger.info(
          "Poll complete: fetched=#{length(features)}, created=#{length(created)}, changed=#{length(changed)}, resolved=#{length(resolved_source_ids)}"
        )

        :ok
    end
  end

  defp build_row(feature, now) do
    %{
      source_id: get_in(feature, ["properties", "GlobalID"]),
      feature: feature,
      feature_hash: :crypto.hash(:sha256, Jason.encode!(feature)),
      inserted_at: now,
      updated_at: now
    }
  end

  defp schedule_poll(delay), do: Process.send_after(self(), :poll, delay)

  defp interval, do: Application.get_env(:wildfire, :poll_interval, 900_000)
end
