class AddEducationAttrToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :serialize_with_project, :boolean, default: true
  end
end
