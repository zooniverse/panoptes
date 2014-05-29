class RenameUserIdToOwnerIdForUserSubjectCollection < ActiveRecord::Migration
  def change
    rename_column :user_subject_collections, :user_id, :owner_id
  end
end
