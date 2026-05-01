defmodule Wildfire.Data.Schema.IncidentEvents do
  use Ecto.Schema
  import Ecto.Changeset

  @types [:created, :updated, :resolved]
  @required_fields [:type, :event]
  @allowed_fields @required_fields ++ []

  schema "incident_events" do
    field(:type, Ecto.Enum, values: @types)
    field(:event, :map)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, @types)
  end
end
