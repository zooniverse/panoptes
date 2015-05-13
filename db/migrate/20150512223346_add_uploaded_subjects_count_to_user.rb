class AddUploadedSubjectsCountToUser < ActiveRecord::Migration
  def change
    add_column :users, :uploaded_subjects_count, :integer, default: 0
  end
end
