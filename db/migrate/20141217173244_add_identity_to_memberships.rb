class AddIdentityToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :identity, :boolean
  end
end
