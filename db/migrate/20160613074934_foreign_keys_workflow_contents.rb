class ForeignKeysWorkflowContents < ActiveRecord::Migration
  def change
    WorkflowContent.joins("LEFT OUTER JOIN workflows ON workflows.id = workflow_contents.workflow_id").where("workflow_contents.workflow_id IS NOT NULL AND workflows.id IS NULL").delete_all
    add_foreign_key :workflow_contents, :workflows, on_update: :cascade, on_delete: :cascade
  end
end
