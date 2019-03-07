class CreateFieldGuideVersions < ActiveRecord::Migration
  def change
    create_table :field_guide_versions do |t|
      t.references :field_guide, index: true, foreign_key: true, null: false
      t.json :items

      t.timestamps null: false
    end
  end
end
