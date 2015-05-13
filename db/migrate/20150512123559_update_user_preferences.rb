class UpdateUserPreferences < ActiveRecord::Migration
  def change
    %i(user_project_preferences user_collection_preferences).each do |table|
      remove_column table, :roles, :string, array: true, null: false, default: []
    end
    add_column :user_project_preferences, :activity_count, :integer
  end
end
