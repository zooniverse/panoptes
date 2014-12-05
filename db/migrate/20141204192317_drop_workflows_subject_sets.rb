class DropWorkflowsSubjectSets < ActiveRecord::Migration
  def change
    drop_table :subject_sets_workflows
  end
end
