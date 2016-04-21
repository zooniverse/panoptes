class AddLaunchDateToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :launch_date, :timestamp
  end
end
