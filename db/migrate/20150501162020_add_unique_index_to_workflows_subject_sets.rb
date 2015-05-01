class AddUniqueIndexToWorkflowsSubjectSets < ActiveRecord::Migration
  def change
    add_index :subject_sets_workflows, [:workflow_id, :subject_set_id], unique: true
  end
end
