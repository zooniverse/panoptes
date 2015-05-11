class AddUrlsToProject < ActiveRecord::Migration
  def change
    add_column :projects, :urls, :jsonb, default: []
    add_column :project_contents, :url_labels, :jsonb, default: {}
  end
end
