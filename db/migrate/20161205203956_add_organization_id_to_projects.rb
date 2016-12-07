class AddOrganizationIdToProjects < ActiveRecord::Migration
  def change
    add_reference :projects, :organization, index: true
    add_foreign_key :projects, :organizations
  end
end
