class AddFieldGuideResource < ActiveRecord::Migration
  def change
    create_table :field_guides do |t|
      t.json :items, default: []
      t.text :language, index: true
      t.references :project, index: true
      t.timestamps null: false
    end
  end
end
