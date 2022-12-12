class AlterSubjectWorkflowCountsAddSubjectId < ActiveRecord::Migration
  def up
    add_column :subject_workflow_counts, :subject_id, :integer, index: true
    add_foreign_key :subject_workflow_counts, :subjects, on_delete: :restrict

    # Follow-up migration should:
    #    add_index :subject_workflow_counts, [:subject_id, :workflow_id], unique: true
    #    change_column_null :subject_workflow_counts, :subject_id, false
  end

  def down
    remove_column :subject_workflow_counts, :subject_id
  end
end
