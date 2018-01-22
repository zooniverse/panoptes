class AddAnnouncementToOrganizationContents < ActiveRecord::Migration
  def change
    add_column :organization_contents, :announcement, :string, default: ""
  end
end
