class DeleteVisibilityFromProjectAndCollection < ActiveRecord::Migration
  def change
    remove_column :projects, :visibility
    remove_column :collections, :visibility
  end
end
