class CreateUserProjectPreferences < ActiveRecord::Migration
  def change
    create_table :user_project_preferences do |t|
      t.references :user, index: true
      t.references :project, index: true
      t.boolean :email_communication
      t.json :preferences

      t.timestamps
    end
  end
end
