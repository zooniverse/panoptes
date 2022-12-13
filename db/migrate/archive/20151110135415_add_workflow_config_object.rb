class AddWorkflowConfigObject < ActiveRecord::Migration
  def change
    add_column :workflows, :config, :jsonb, default: {}, null: false
  end
end
