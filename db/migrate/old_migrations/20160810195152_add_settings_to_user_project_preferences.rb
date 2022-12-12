class AddSettingsToUserProjectPreferences < ActiveRecord::Migration
  def change
    add_column :user_project_preferences, :settings, :jsonb, default: { }
  end
end
