class ChangeWorkflowStepsDefault < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        change_column_default(:workflows, :steps, [])
        Workflow.find_each do |wf|
          wf.update_column(:steps, [])
        end
      end
    end
  end
end
