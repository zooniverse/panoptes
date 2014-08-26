class AddRolesToUserProjectPreferences < ActiveRecord::Migration
  def change
    add_column :user_project_preferences, :roles, :string, array: true, default: [], null: false
  end
end
