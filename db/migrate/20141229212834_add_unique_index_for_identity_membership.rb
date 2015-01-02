class AddUniqueIndexForIdentityMembership < ActiveRecord::Migration
  def change
    add_index :memberships, [:user_id, :identity], unique: true, where: "identity = true"
  end
end
