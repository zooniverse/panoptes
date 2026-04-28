class AddIndexTsvToUserGroups < ActiveRecord::Migration[6.1]
  # Adding an index non-concurrently blocks writes. Therefore we need to disable ddl transaction

  disable_ddl_transaction!

  def up
    add_index :user_groups, :tsv, using: "gin", algorithm: :concurrently
  end

  def down
    remove_index :user_groups, :tsv
  end
end
