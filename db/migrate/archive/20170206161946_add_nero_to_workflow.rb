class AddNeroToWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :nero_config, :jsonb, default: {}
  end
end
