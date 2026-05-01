defmodule Wildfire.ESRI do
  require Logger

  @endpoint "https://services3.arcgis.com/T4QMspbfLg3qTGWY/arcgis/rest/services/WFIGS_Incident_Locations_Current/FeatureServer/0/query"
  @page_size 2000

  def fetch_incidents(opts \\ []) do
    req_opts = Application.get_env(:wildfire, :esri_req_options, [])
    merged = Keyword.merge(req_opts, opts)
    fetch_page(0, [], merged)
  end

  defp fetch_page(offset, acc, opts) do
    params = %{
      where: "1=1",
      outFields: "*",
      f: "geojson",
      outSR: "4326",
      resultOffset: offset,
      resultRecordCount: @page_size
    }

    req = Req.new(url: @endpoint, params: params) |> Req.merge(opts)

    case Req.get(req) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        features = body["features"] || []
        new_acc = acc ++ features

        if get_in(body, ["properties", "exceededTransferLimit"]) == true do
          fetch_page(offset + @page_size, new_acc, opts)
        else
          {:ok, new_acc}
        end

      {:ok, %Req.Response{status: status}} ->
        Logger.warning("ESRI page fetch failed: status #{status}, offset #{offset}")
        {:ok, acc}

      {:error, reason} ->
        Logger.warning("ESRI page fetch error: #{inspect(reason)}, offset #{offset}")
        {:ok, acc}
    end
  end
end
