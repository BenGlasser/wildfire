defmodule WildfireWeb.PageLive do
  use WildfireWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>hello world</h1>
    <div id="spike001-map" phx-hook="MapHook" data-points="ping">
      hook target (server-rendered fallback)
    </div>
    """
  end
end
