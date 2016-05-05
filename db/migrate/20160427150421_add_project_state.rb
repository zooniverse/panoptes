class AddProjectState < ActiveRecord::Migration
  def change
    add_column :projects, :state, :integer
    add_index :projects, :state
  end
end
