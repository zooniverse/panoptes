class UserUploadWhitelist < ActiveRecord::Migration
  def change
    add_column :users, :upload_whitelist, :boolean, default: false, null: false
  end
end
