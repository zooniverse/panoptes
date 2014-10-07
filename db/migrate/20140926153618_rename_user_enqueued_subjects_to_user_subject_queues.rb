class RenameUserEnqueuedSubjectsToUserSubjectQueues < ActiveRecord::Migration
  def change
    rename_table :user_enqueued_subjects, :user_subject_queues
  end
end
