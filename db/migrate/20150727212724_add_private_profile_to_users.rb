class AddPrivateProfileToUsers < ActiveRecord::Migration
  def change
    add_column :users, :private_profile, :boolean, index: { where: "(private_profile = false)" }, default: true
  end
end
