class AddTsvToOrganizations < ActiveRecord::Migration[6.1]
  def up
    add_column :organizations, :tsv, :tsvector

    safety_assured do
      execute <<~SQL
        UPDATE organizations
        SET tsv = to_tsvector('pg_catalog.english', coalesce(display_name, ''))
        WHERE tsv IS NULL;
      SQL
    end
  end

  def down
    remove_column :organizations, :tsv
  end
end
