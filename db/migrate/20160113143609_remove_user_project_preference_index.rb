class RemoveUserProjectPreferenceIndex < ActiveRecord::Migration
  def change
    remove_index :user_project_preferences, column: :project_id
    remove_index :user_project_preferences, column: :user_id
  end
end
