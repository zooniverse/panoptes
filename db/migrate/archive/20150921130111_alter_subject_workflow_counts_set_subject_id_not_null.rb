class AlterSubjectWorkflowCountsSetSubjectIdNotNull < ActiveRecord::Migration
  def change
    add_index :subject_workflow_counts, [:subject_id, :workflow_id], unique: true
    change_column_null :subject_workflow_counts, :subject_id, false
  end
end
