class AddOrderToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :display_order, :integer, index: true
  end
end
