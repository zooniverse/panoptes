class AddUniqNamingIndexes < ActiveRecord::Migration
  def change
    add_index :user_groups, :display_name, unique: true
  end
end
