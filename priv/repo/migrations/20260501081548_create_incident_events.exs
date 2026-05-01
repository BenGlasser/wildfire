defmodule Wildfire.Repo.Migrations.CreateIncidentEvents do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE incident_event_type AS ENUM ('created', 'updated', 'resolved')")

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

  def down do
    drop(table(:incident_events))
    execute("DROP TYPE incident_event_type")
  end
end
