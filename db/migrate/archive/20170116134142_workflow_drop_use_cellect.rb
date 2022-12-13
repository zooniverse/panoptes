class WorkflowDropUseCellect < ActiveRecord::Migration
  def change
    remove_column :workflows, :use_cellect
  end
end
