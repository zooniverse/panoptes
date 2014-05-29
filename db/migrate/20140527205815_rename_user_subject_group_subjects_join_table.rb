class RenameUserSubjectGroupSubjectsJoinTable < ActiveRecord::Migration
  def change
    rename_table :subjects_user_subject_groups, :user_subject_collections_subjects
    rename_column :user_subject_collections_subjects, :user_subject_group_id, :user_subject_collection_id
  end
end
