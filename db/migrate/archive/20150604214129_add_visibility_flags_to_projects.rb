class AddVisibilityFlagsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :launch_requested, :boolean, default: false
    add_column :projects, :launch_approved, :boolean, default: false
    add_column :projects, :beta_requested, :boolean, default: false
    add_column :projects, :beta_approved, :boolean, default: false

    Project.find_each do |project|
      project.beta_approved = project.beta
      project.launch_approved = project.approved
    end

    remove_column :projects, :beta
    remove_column :projects, :approved

    add_index :projects, :beta_approved
    add_index :projects, :launch_approved
    add_index :projects, :beta_requested, where: "beta_requested IS TRUE"
    add_index :projects, :launch_requested, where: "launch_requested IS TRUE"
  end
end
