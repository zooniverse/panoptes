class CreateUriNames < ActiveRecord::Migration
  def change
    create_table :uri_names do |t|
      t.string :name
      t.string :resource_type
      t.integer :resource_id

      t.timestamps
    end
    add_index :uri_names, :name, unique: true
  end
end
