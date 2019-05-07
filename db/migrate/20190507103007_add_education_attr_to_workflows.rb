class AddEducationAttrToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :education_api, :boolean, default: false
  end
end
