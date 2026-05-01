defmodule Wildfire.Repo do
  use Ecto.Repo,
    otp_app: :wildfire,
    adapter: Ecto.Adapters.Postgres
end
