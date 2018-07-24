class AddWorkflowPublishedVersion < ActiveRecord::Migration
  def change
    add_column :workflows, :published_version_id, :integer, null: true
    add_foreign_key :workflows, :workflow_versions, column: "published_version_id"
  end
end
