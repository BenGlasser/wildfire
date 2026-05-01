defmodule WildfireWeb.D3Live do
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
    <div style="background:#07080c; color:#f5e9d2; min-height:100vh; padding:24px; font:14px/1.4 ui-sans-serif,system-ui,-apple-system;">
      <h1 style="margin:0 0 4px 0; font-weight:600; letter-spacing:0.02em;">
        Wildfire <span style="color:#ffb45a">·</span> Live
      </h1>
      <div style="opacity:.6; margin-bottom:18px;">
        {@count} active incidents · drag to pan · scroll to zoom · hover for detail
      </div>
      <div
        id="d3-map"
        phx-hook="D3Map"
        phx-update="ignore"
        data-points={Jason.encode!(@points)}
        style="height: 78vh; width: 100%; border: 1px solid rgba(255,200,140,0.18); border-radius: 10px; overflow:hidden; box-shadow: 0 10px 40px rgba(0,0,0,0.6);"
      >
      </div>
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
