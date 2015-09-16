class RemoveUserUploadedSubjectCounter < ActiveRecord::Migration
  def change
    remove_column :users, :uploaded_subjects_count, :integer, default: 0
  end
end
