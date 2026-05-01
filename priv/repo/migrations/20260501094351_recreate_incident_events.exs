defmodule Wildfire.Repo.Migrations.RecreateIncidentEvents do
  use Ecto.Migration

  def up do
    drop(table(:incident_events))

    create table(:incident_events) do
      add(:type, :incident_event_type, null: false)
      add(:event, :map, null: false)
    end

    create(index(:incident_events, [:type]))
  end

  def down do
    drop(table(:incident_events))

    create table(:incident_events) do
      add(:object_id, :bigint, null: false)
      add(:type, :incident_event_type, null: false)
      add(:occurred_at, :naive_datetime, null: false)
      add(:feature, :map, null: false)
      add(:inserted_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create(index(:incident_events, [:object_id, :occurred_at]))
    create(index(:incident_events, [:type]))
  end
end
