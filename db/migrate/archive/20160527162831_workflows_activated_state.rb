class WorkflowsActivatedState < ActiveRecord::Migration
  def change
    add_column :workflows, :activated_state, :integer, default: 0, null: false
  end
end
