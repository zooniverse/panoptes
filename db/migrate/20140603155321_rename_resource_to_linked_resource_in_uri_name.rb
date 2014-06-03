class RenameResourceToLinkedResourceInUriName < ActiveRecord::Migration
  def change
    rename_column :uri_names, :resource_id, :linked_resource_id
    rename_column :uri_names, :resource_type, :linked_resource_type
  end
end
