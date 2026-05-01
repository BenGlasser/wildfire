defmodule Wildfire.MixProject do
  use Mix.Project

  def project do
    [
      app: :wildfire,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Wildfire.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22.0"},
      {:bandit, "~> 1.10"},
      {:plug, "~> 1.16"},
      {:websock, "~> 0.5"},
      {:websock_adapter, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:telemetry, "~> 1.0"}
    ]
  end
end
