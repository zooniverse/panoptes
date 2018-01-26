class AddAnnouncementToOrganizationContents < ActiveRecord::Migration
  def change
    add_column :organization_contents, :announcement, :string, default: ""
    Medium.where(type: "org_attached_image").update_all(type: "organization_attached_image")
  end
end
