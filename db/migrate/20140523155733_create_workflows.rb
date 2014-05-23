class CreateWorkflows < ActiveRecord::Migration
  def change
    create_table :workflows do |t|
      t.string :name
      t.json :tasks
      t.integer :classification_count
      t.references :project, index: true

      t.timestamps
    end
  end
end
