class AddLiveFieldToProjects < ActiveRecord::Migration

  #ensure the project AR model always exits outside the /model definition
  class Project < ActiveRecord::Base
  end

  def up
    add_column :projects, :live, :boolean, index: true, default: false, null: false
    Project.update_all(live: false)
  end

  def down
    remove_column :projects, :live
  end
end
