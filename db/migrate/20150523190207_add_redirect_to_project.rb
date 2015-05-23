class AddRedirectToProject < ActiveRecord::Migration
  def change
    add_column :projects, :redirect, :text, default: ""
    Project.update_all("redirect = configuration->>'redirect'")
  end
end
