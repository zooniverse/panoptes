class AddUserUploadWhitelistNullDefault < ActiveRecord::Migration
  def change
    change_column_null(:users, :upload_whitelist, false)
  end
end
