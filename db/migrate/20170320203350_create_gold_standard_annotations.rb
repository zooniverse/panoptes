class CreateGoldStandardAnnotations < ActiveRecord::Migration
  def change
    create_table :gold_standard_annotations do |t|
      t.references :project, foreign_key: true
      t.references :workflow, index: true, foreign_key: true
      t.references :subject, index: true, foreign_key: true
      t.references :user, foreign_key: true
      t.references :classification, foreign_key: true

      t.json :annotations, null: false
      t.json :metadata, null: false

      t.timestamps null: false
    end
  end
end
