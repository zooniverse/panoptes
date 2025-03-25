class AddIndexSubjectsUploadUserId < ActiveRecord::Migration
  def up
    change_column :subjects, :upload_user_id, 'integer USING CAST(upload_user_id AS integer)'
    add_index :subjects, :upload_user_id
  end

  def down
    change_column :subjects, :upload_user_id, :string
    remove_index :subjects, :upload_user_id
  end
end
