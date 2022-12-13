class CollectionsBelongsToManyProjects < ActiveRecord::Migration
  def change
    add_column :collections, :project_ids, :integer, array: true, default: []
    Collection.where.not(project_id: nil).update_all("project_ids = ARRAY[project_id]")
    add_index  :collections, :project_ids, using: 'gin'
    remove_column :collections, :project_id
  end
end
