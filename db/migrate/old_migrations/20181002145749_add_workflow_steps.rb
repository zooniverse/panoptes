class AddWorkflowSteps < ActiveRecord::Migration
  def change
    add_column :workflows, :steps, :jsonb

    reversible do |dir|
      dir.up do
        change_column_default(:workflows, :steps, {})
        Workflow.update_all(steps: {})
        change_column_null :workflows, :steps, false
      end
    end
  end
end
