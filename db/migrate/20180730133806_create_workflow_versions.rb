class CreateWorkflowVersions < ActiveRecord::Migration
  def change
    create_table :workflow_versions do |t|
      t.references :workflow, foreign_key: true, null: false
      t.jsonb :tasks, null: false, default: {}
      t.string :first_task, null: false

      t.timestamps null: false
    end

    create_table :workflow_content_versions do |t|
      t.references :workflow_version, foreign_key: true, null: false
      t.references :workflow_content, foreign_key: true, null: false
      t.string :language, null: false
      t.jsonb :strings, null: false, default: {}
    end

    add_column :workflow_versions, :primary_content_id, :integer, null: true
    add_foreign_key :workflow_versions, :workflow_content_versions, column: "primary_content_id"
  end
end
