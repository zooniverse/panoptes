class CreateUserGroupMemberships < ActiveRecord::Migration
  def change
    create_table :user_group_memberships do |t|
      t.integer :state
      t.references :user_group, index: true
      t.references :user, index: true

      t.timestamps
    end
  end
end
