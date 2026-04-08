# frozen_string_literal: true

class AddIndexTsvToOrganizations < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    add_index :organizations, :tsv, using: 'gin', algorithm: :concurrently
    add_index :organizations,
              "coalesce(display_name, '')",
              using: 'gin',
      opclass: :gin_trgm_ops,
      name: 'index_organizations_display_name_trgrm',
      algorithm: :concurrently
  end

  def down
    remove_index :organizations, name: 'index_organizations_display_name_trgrm'
    remove_index :organizations, :tsv
  end
end
