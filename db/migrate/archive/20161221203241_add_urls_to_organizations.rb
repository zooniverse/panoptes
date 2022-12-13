class AddUrlsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :urls, :jsonb, default: []
    add_column :organization_contents, :url_labels, :jsonb, default: {}
  end
end
