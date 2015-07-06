class AddLegacyProjectIndexes < ActiveRecord::Migration
  def change
    add_index :projects, :migrated, where: "migrated = TRUE"
  end
end
