class AddUploadingUserIdToSubject < ActiveRecord::Migration
  def change
    add_column :subjects, :upload_user_id, :string
  end

end
