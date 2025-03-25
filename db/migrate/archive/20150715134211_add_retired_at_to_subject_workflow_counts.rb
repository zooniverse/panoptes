class AddRetiredAtToSubjectWorkflowCounts < ActiveRecord::Migration
  def change
    add_column :subject_workflow_counts, :retired_at, :timestamp
  end
end
