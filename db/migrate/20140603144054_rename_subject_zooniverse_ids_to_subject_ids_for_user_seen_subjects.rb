class RenameSubjectZooniverseIdsToSubjectIdsForUserSeenSubjects < ActiveRecord::Migration
  def change
    remove_column :user_seen_subjects, :subject_zooniverse_ids
    add_column :user_seen_subjects, :subject_ids, :integer, array: true
  end
end
