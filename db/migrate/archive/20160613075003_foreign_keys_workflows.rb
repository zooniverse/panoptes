class ForeignKeysWorkflows < ActiveRecord::Migration
  def change
    workflow_ids = Workflow.joins("LEFT OUTER JOIN projects ON projects.id = workflows.project_id").where("workflows.project_id IS NOT NULL AND projects.id IS NULL").pluck("workflows.id")
    SubjectWorkflowStatus.where(workflow_id: workflow_ids).delete_all
    Workflow.where(id: workflow_ids).delete_all
    add_foreign_key :workflows, :projects, on_update: :cascade, on_delete: :restrict
    add_foreign_key :workflows, :subjects, column: :tutorial_subject_id, on_update: :cascade, on_delete: :restrict
  end
end
