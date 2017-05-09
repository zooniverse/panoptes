class CreateClassificationsExportSegments < ActiveRecord::Migration
  def change
    create_table :classifications_export_segments do |t|
      t.references :project, null: false, index: true, foreign_key: true
      t.references :workflow, null: false, index: true, foreign_key: true
      t.integer :first_classification_id, null: false
      t.integer :last_classification_id, null: false
      t.integer :requester_id, null: false

      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps null: false
    end

    add_foreign_key :classifications_export_segments, :classifications, column: :first_classification_id
    add_foreign_key :classifications_export_segments, :classifications, column: :last_classification_id
    add_foreign_key :classifications_export_segments, :users, column: :requester_id
  end
end
