defmodule WildfireWeb.LeafletLive do
  use WildfireWeb, :live_view

  alias Wildfire.Repo
  alias Wildfire.Data.Schema.Incident

  @impl true
  def mount(_params, _session, socket) do
    points =
      Repo.all(Incident)
      |> Enum.map(&to_point/1)
      |> Enum.reject(&is_nil/1)

    {:ok, assign(socket, points: points, count: length(points))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Spike 002a — Leaflet ({@count} incidents)</h1>
    <div
      id="leaflet-map"
      phx-hook="LeafletMap"
      phx-update="ignore"
      data-points={Jason.encode!(@points)}
      style="height: 80vh; width: 100%;"
    >
    </div>
    """
  end

  defp to_point(%Incident{
         feature: %{
           "geometry" => %{"type" => "Point", "coordinates" => [lon, lat]},
           "properties" => props
         },
         source_id: id
       }) do
    %{
      id: id,
      lon: lon,
      lat: lat,
      name: props["IncidentName"],
      size: parse_num(props["IncidentSize"])
    }
  end

  defp to_point(_), do: nil

  defp parse_num(n) when is_number(n), do: n

  defp parse_num(s) when is_binary(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> nil
    end
  end

  defp parse_num(_), do: nil
end
