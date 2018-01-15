class ConvertCollectionBelongsToMany < ActiveRecord::Migration
  def change
    create_table :collections_projects, id: false do |t|
      t.references :collection, index: true, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
    end
  end
end
