class AddWorkflowVersionIdToClassifications < ActiveRecord::Migration
  def change
    add_reference :classifications, :workflow_version, index: true
  end
end
