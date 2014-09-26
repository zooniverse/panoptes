class SetDefaultMembershipStateAndRoles < ActiveRecord::Migration
  def change
    change_column :memberships, :state, :integer, default: 2, null: false
    change_column :memberships, :roles, :string, array: true, default: ["group_member"], null: false
  end
end
