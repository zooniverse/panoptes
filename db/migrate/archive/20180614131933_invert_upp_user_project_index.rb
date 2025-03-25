class InvertUppUserProjectIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :user_project_preferences,
      %i(project_id user_id),
      unique: true,
      algorithm: :concurrently

    remove_index :user_project_preferences,
      column: %i(user_id project_id),
      unique: true
  end
end
