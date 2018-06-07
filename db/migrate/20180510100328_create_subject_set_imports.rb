class CreateSubjectSetImports < ActiveRecord::Migration
  def change
    create_table :subject_set_imports do |t|
      t.references :subject_set, index: true, foreign_key: true, null: false
      t.references :user, index: true, foreign_key: true, null: false
      t.string :source_url
      t.integer :imported_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.string :failed_uuids, array: true, null: false, default: []

      t.timestamps null: false
    end
  end
end
