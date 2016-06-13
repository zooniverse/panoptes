class ForeignKeysProjectPages < ActiveRecord::Migration
  def change
    ProjectPage.joins("LEFT OUTER JOIN projects ON projects.id = project_pages.project_id").where("project_pages.project_id IS NOT NULL AND projects.id IS NULL").delete_all
    add_foreign_key :project_pages, :projects, on_update: :cascade, on_delete: :cascade
  end
end
