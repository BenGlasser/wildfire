defmodule Wildfire.Poller do
  use GenServer
  require Logger

  import Ecto.Query

  alias Wildfire.Repo
  alias Wildfire.Incident

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

        old_hashes =
          from(i in Incident,
            where: i.source_id in ^source_ids,
            select: {i.source_id, i.feature_hash}
          )
          |> Repo.all()
          |> Map.new()

        changed =
          Enum.filter(candidates, fn row ->
            Map.get(old_hashes, row.source_id) != row.feature_hash
          end)

        changed
        |> Enum.chunk_every(500)
        |> Enum.each(fn chunk ->
          Repo.insert_all(Incident, chunk,
            on_conflict: {:replace, [:feature, :feature_hash, :updated_at]},
            conflict_target: :source_id
          )
        end)

        if changed != [] do
          Wildfire.WebSocket.Manager.broadcast(
            :incidents,
            %{changed_incidents: Enum.map(changed, & &1.feature)}
          )

          Logger.info("Broadcast #{length(changed)} changed incidents")
        end

        Logger.info("Poll complete: fetched=#{length(features)}, changed=#{length(changed)}")
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
