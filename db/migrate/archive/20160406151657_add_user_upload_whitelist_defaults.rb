class AddUserUploadWhitelistDefaults < ActiveRecord::Migration
  def change
    change_column_default(:users, :upload_whitelist, false)
  end
end
