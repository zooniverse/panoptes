class AddProjectState < ActiveRecord::Migration
  def change
    add_column :projects, :state, :integer
  end
end
