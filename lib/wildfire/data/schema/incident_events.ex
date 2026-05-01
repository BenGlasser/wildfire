defmodule Wildfire.Data.Schema.IncidentEvents do
  use Ecto.Schema
  import Ecto.Changeset

  @types [:created, :updated, :resolved]
  @required_fields [:object_id, :type, :occurred_at, :feature]
  @allowed_fields @required_fields ++ []

  schema "incident_events" do
    field(:object_id, :integer)
    field(:type, Ecto.Enum, values: @types)
    field(:occurred_at, :naive_datetime)
    field(:feature, :map)

    timestamps(updated_at: false)
  end


  def changeset(event, attrs) do
    event
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, @types)
  end
end
