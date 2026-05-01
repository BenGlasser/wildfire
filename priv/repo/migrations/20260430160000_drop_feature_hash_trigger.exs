defmodule Wildfire.Repo.Migrations.DropFeatureHashTrigger do
  use Ecto.Migration

  def up do
    execute("DROP TRIGGER IF EXISTS incidents_feature_hash_trigger ON incidents")
    execute("DROP FUNCTION IF EXISTS compute_feature_hash()")
  end

  def down do
    execute("""
    CREATE OR REPLACE FUNCTION compute_feature_hash()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.feature_hash := digest(NEW.feature::text, 'sha256');
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER incidents_feature_hash_trigger
      BEFORE INSERT OR UPDATE ON incidents
      FOR EACH ROW
      EXECUTE FUNCTION compute_feature_hash();
    """)
  end
end
