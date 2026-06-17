class AddSubjectsCountToCollections < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :collections, :subjects_count, :integer, default: 0
    add_index :collections, :subjects_count, algorithm: :concurrently
  end
end
