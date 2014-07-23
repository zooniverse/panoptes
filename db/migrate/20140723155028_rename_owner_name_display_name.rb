class RenameOwnerNameDisplayName < ActiveRecord::Migration
  def change
    rename_column :user_groups, :display_name, :name
    add_column :user_groups, :display_name, :string
  end
end
