class AddProjectIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :project_id, :integer
  end
end
