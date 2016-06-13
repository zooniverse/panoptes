class ForeignKeysUserProjectPreferences < ActiveRecord::Migration
  def change
    UserProjectPreference.joins("LEFT OUTER JOIN projects ON projects.id = user_project_preferences.project_id").where("user_project_preferences.project_id IS NOT NULL AND projects.id IS NULL").delete_all
    add_foreign_key :user_project_preferences, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :user_project_preferences, :projects, on_update: :cascade, on_delete: :cascade
  end
end
