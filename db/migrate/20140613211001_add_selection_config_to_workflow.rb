class AddSelectionConfigToWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :pairwise, :boolean, default: false, null: false
    add_column :workflows, :grouped_selection, :boolean, default: false, null: false
    add_column :workflows, :selection, :integer, default: 0, null: false
  end
end
