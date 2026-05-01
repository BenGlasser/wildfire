defmodule Wildfire.Incident do
  use Ecto.Schema

  schema "incidents" do
    field :source_id, :string
    field :feature, :map
    field :feature_hash, :binary
    timestamps()
  end
end
