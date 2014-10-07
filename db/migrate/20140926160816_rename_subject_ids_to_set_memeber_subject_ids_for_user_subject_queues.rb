class RenameSubjectIdsToSetMemeberSubjectIdsForUserSubjectQueues < ActiveRecord::Migration
  def change
    rename_column :user_subject_queues, :subject_ids, :set_member_subject_ids
  end
end
