class AddSelectionConfigToWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :pairwise, :boolean, default: false, null: false
    add_column :workflows, :grouped, :boolean, default: false, null: false
    add_column :workflows, :prioritized, :boolean, default: false, null: false
  end
end
