class AddLegacyCountToProjectPreferences < ActiveRecord::Migration
  def change
    add_column :user_project_preferences, :legacy_count, :jsonb, default: {}
  end
end
