# frozen_string_literal: true

class AddIndexTsvToOrganizations < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    add_index :organizations, :tsv, using: 'gin', algorithm: :concurrently, if_not_exists: true

    safety_assured do
      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_organizations_display_name_trgrm
        ON organizations
        USING gin (coalesce(display_name::text, '') gin_trgm_ops);
      SQL
    end
  end

  def down
    safety_assured do
      execute <<~SQL.squish
        DROP INDEX CONCURRENTLY IF EXISTS index_organizations_display_name_trgrm;
      SQL
    end

    remove_index :organizations, :tsv, algorithm: :concurrently, if_exists: true
  end
end
