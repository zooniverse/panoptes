class AddVisibilityToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :visibility, :string
  end
end
