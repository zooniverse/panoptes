class RenameGroupedSubjectsToSetMemberSubjects < ActiveRecord::Migration
  def change
    rename_table :grouped_subjects, :set_member_subjects
    rename_column :classifications, :grouped_subject_id, :set_member_subject_id
  end
end
