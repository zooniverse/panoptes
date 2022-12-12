class RemoveWorkflowsNeroConfig < ActiveRecord::Migration
  def change
    remove_column :workflows, :nero_config, :jsonb, default: {}
  end
end
