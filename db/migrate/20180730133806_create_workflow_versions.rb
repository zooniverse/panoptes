class CreateWorkflowVersions < ActiveRecord::Migration
  def change
    create_table :workflow_versions do |t|
      t.references :workflow, foreign_key: true, null: false
      t.jsonb :tasks, null: false, default: {}
      t.string :first_task, null: false

      t.timestamps null: false
    end
  end
end
