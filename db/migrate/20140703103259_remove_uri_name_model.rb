class RemoveUriNameModel < ActiveRecord::Migration
  def up
    drop_table :uri_names
  end

  def down
    create_table :uri_names do |t|
      t.string :name
      t.string :resource_type
      t.integer :resource_id

      t.timestamps
    end
    add_index :uri_names, :name, unique: true
  end
end
