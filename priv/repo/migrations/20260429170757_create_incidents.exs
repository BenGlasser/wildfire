defmodule Wildfire.Repo.Migrations.CreateIncidents do
  use Ecto.Migration

  def up do
    create table(:incidents) do
      add :source_id, :string, null: false, size: 255
      add :feature, :map, null: false
      add :feature_hash, :binary
      timestamps()
    end

    create unique_index(:incidents, [:source_id])

    execute """
    CREATE OR REPLACE FUNCTION compute_feature_hash()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.feature_hash := digest(NEW.feature::text, 'sha256');
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER incidents_feature_hash_trigger
      BEFORE INSERT OR UPDATE ON incidents
      FOR EACH ROW
      EXECUTE FUNCTION compute_feature_hash();
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS incidents_feature_hash_trigger ON incidents"
    execute "DROP FUNCTION IF EXISTS compute_feature_hash()"
    drop table(:incidents)
  end
end
