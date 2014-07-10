class AddUriNameUniqCaseSensitiveIndex < ActiveRecord::Migration
  def up
    remove_index :uri_names, :name
    add_index :uri_names, :name, unique: true, case_sensitive: false
  end

  def down
    remove_index :uri_names, :name
    add_index :uri_names, :name, unique: true
  end
end
