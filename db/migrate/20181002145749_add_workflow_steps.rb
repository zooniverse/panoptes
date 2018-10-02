class AddWorkflowSteps < ActiveRecord::Migration
  def change
    add_column :workflows, :steps, :jsonb
  end
end
