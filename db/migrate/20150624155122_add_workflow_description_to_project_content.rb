class AddWorkflowDescriptionToProjectContent < ActiveRecord::Migration
  def change
    add_column :project_contents, :workflow_description, :text, default: ""
  end
end
