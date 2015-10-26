class AddProjectLaunchDate < ActiveRecord::Migration
  def change
    add_column :projects, :launch_date, :datetime
  end
end
