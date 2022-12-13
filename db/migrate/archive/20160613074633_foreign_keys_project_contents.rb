class ForeignKeysProjectContents < ActiveRecord::Migration
  def change
    ProjectContent.joins("LEFT OUTER JOIN projects ON projects.id = project_contents.project_id").where("project_contents.project_id IS NOT NULL AND projects.id IS NULL").delete_all
    add_foreign_key :project_contents, :projects, on_update: :cascade, on_delete: :cascade
  end
end
