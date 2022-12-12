class AddProjectVersions < ActiveRecord::Migration
  def change
    create_table :project_versions do |t|
      t.references :project, foreign_key: true, null: true

      t.boolean :private
      t.boolean :live, null: false
      t.boolean :beta_requested
      t.boolean :beta_approved
      t.boolean :launch_requested
      t.boolean :launch_approved

      t.string :display_name
      t.text :description
      t.text :introduction
      t.jsonb :url_labels
      t.text :workflow_description
      t.text :researcher_quote
    end
  end
end
