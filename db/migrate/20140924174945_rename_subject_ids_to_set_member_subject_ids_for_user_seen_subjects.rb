class RenameSubjectIdsToSetMemberSubjectIdsForUserSeenSubjects < ActiveRecord::Migration
  def change
    remove_column :user_seen_subjects, :subject_ids, :integer, array: true, default: [], null: false
    add_column :user_seen_subjects, :set_member_subject_ids, :integer, array: true, default: [], null: false
  end
end
