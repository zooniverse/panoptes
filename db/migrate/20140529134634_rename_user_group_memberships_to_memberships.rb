class RenameUserGroupMembershipsToMemberships < ActiveRecord::Migration
  def change
    rename_table :user_group_memberships, :memberships
  end
end
