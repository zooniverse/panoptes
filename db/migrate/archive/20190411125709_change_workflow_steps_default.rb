class ChangeWorkflowStepsDefault < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        change_column_default(:workflows, :steps, [])
        Workflow.select(:id).find_in_batches do |workflows|
          workflows_update_scope = Workflow.where(id: workflows)
          workflows_update_scope.update_all(steps: [])
        end
      end
    end
  end
end
