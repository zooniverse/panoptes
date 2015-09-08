class AddIndexToProjectPreferencesUpdatedAt < ActiveRecord::Migration
  def change
    add_index :user_project_preferences, :updated_at
  end
end
