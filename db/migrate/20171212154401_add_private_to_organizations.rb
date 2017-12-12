class AddPrivateToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :private, :boolean, default: false
  end
end
