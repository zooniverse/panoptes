class AddLiveFieldToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :live, :boolean, index: true, default: false
  end
end
