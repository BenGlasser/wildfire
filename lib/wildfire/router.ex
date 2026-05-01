defmodule Wildfire.Router do
  use Plug.Router
  use Wildfire.WebSocket.Routes

  plug :match
  plug :dispatch

  get "/test" do
    path = Path.join(:code.priv_dir(:wildfire), "static/ws_test.html")

    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, path)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
