class RenameSubjectGroupIdToSubjectSetIdInSetMemberSubjects < ActiveRecord::Migration
  def change
    rename_column :set_member_subjects, :subject_group_id, :subject_set_id
  end
end
