class AddVisibleToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :visible_to, :string, array: true, default: [], null: false
  end
end
