class ForeignKeysSubjects < ActiveRecord::Migration
  def change
    Subject.joins("LEFT OUTER JOIN projects ON projects.id = subjects.project_id").where("subjects.project_id IS NOT NULL AND projects.id IS NULL").update_all(project_id: nil)
    Subject.joins("LEFT OUTER JOIN users ON users.id = subjects.upload_user_id").where("subjects.upload_user_id IS NOT NULL AND users.id IS NULL").update_all(upload_user_id: nil)
    add_foreign_key :subjects, :projects, on_update: :cascade, on_delete: :restrict
    add_foreign_key :subjects, :users, column: :upload_user_id, on_update: :cascade, on_delete: :restrict
  end
end
