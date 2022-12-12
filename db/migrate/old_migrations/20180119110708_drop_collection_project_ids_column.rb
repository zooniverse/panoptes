class DropCollectionProjectIdsColumn < ActiveRecord::Migration
  def change
    remove_index  :collections, column: :project_ids
    remove_column :collections, :project_ids, :integer, array: true, default: []
  end
end
