class CreateWorkflowVersions < ActiveRecord::Migration
  def change
    create_table :workflow_versions do |t|
      t.references :workflow, foreign_key: true, null: false

      t.integer :major_version, null: false
      t.integer :minor_version, null: false

      t.boolean :grouped, null: false, default: false
      t.boolean :pairwise, null: false, default: false
      t.boolean :prioritized, null: false, default: false

      t.jsonb :tasks, null: false, default: {}
      t.string :first_task, null: false
      t.jsonb :strings, null: false, default: {}

      t.timestamps null: false
    end
  end
end
