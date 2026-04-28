# frozen_string_literal: true

class CreateSqlTriggerToUpdateOrganizationsTsvVector < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute <<~SQL.squish
        CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
        ON organizations FOR EACH ROW EXECUTE PROCEDURE
        tsvector_update_trigger(
          tsv, 'pg_catalog.english', display_name
        );
      SQL
    end
  end

  def down
    safety_assured do
      execute <<~SQL.squish
        DROP TRIGGER tsvectorupdate
        ON organizations;
      SQL
    end
  end
end
