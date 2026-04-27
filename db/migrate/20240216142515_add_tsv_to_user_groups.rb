class AddTsvToUserGroups < ActiveRecord::Migration[6.1]
  def up
    add_column :user_groups, :tsv, :tsvector
  end

  def down
    remove_column :user_groups, :tsv
  end
end
