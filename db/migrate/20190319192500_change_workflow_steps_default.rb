class ChangeWorkflowStepsDefault < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        change_column_default(:workflows, :steps, [])
        Workflow.update_all(steps: [])
      end
    end
  end
end
