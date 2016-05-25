class EnsureMembershipsAreUnique < ActiveRecord::Migration
  def change
      add_index :memberships, [:user_group_id, :user_id], unique: true
  end
end
