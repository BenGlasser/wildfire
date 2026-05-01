defmodule Wildfire.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Wildfire.Repo,
      {Phoenix.PubSub, name: Wildfire.PubSub},
      {Registry, keys: :duplicate, name: Wildfire.WebSocket.Manager},
      Wildfire.Poller,
      {Bandit, plug: Wildfire.Router, port: Application.get_env(:wildfire, :http_port, 4000)},
      WildfireWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wildfire.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
