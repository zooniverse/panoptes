class AddClassificationExportRowModel < ActiveRecord::Migration
  def change
    create_table :classification_export_rows do |t|
      t.references :classification, null: false, index: true
      t.references :project, null: false, index: true
      t.references :workflow, null: false, index: true
      t.references :user
      t.string :user_name
      t.string :user_ip
      t.string :workflow_name
      t.string :workflow_version
      t.timestamp :classification_created_at
      t.boolean :gold_standard
      t.string :expert
      t.jsonb :metadata
      t.jsonb :annotations
      t.jsonb :subject_data
      t.string :subject_ids
      t.timestamps
    end
  end
end
