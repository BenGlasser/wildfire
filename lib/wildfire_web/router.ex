defmodule WildfireWeb.Router do
  use WildfireWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {WildfireWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", WildfireWeb do
    pipe_through(:browser)

    live("/", PageLive, :index)
  end
end
