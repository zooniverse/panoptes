class AddRolesToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :roles, :string, array: true, default: [], null: false
  end
end
