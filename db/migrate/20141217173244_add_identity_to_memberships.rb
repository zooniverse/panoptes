class AddIdentityToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :identity, :boolean, default: false, null: false
  end
end
