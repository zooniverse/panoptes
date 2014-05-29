class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.string :display_name
      t.integer :classification_count
      t.integer :user_count
      t.references :user_id, index: true

      t.timestamps
    end
    add_index :projects, :name, unique: true
  end
end
