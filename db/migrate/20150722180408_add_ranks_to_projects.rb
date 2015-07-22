class AddRanksToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :launched_row_order, :integer, index: true
    add_column :projects, :beta_row_order, :integer, index: true
  end
end
