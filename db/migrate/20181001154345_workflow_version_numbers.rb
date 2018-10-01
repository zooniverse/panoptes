class WorkflowVersionNumbers < ActiveRecord::Migration
  def change
    add_column :workflows, :major_version, :integer
    add_column :workflows, :minor_version, :integer
  end
end
