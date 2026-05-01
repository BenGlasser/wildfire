defmodule Wildfire.Data.Schema.IncidentEvents do
  use Ecto.Schema
  import Ecto.Changeset

  @types [:created, :updated, :resolved]

  schema "incident_events" do
    field(:object_id, :integer)
    field(:type, Ecto.Enum, values: @types)
    field(:occurred_at, :naive_datetime)
    field(:feature, :map)

    timestamps(updated_at: false)
  end

  @required_fields ~w(object_id type occurred_at feature)a

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, @types)
  end
end
