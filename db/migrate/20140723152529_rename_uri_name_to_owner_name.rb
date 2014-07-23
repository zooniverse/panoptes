class RenameUriNameToOwnerName < ActiveRecord::Migration
  def change
    rename_table :uri_names, :owner_names
  end
end
