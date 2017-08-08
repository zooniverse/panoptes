class AddTranslationResources < ActiveRecord::Migration
  def change
    create_table :translations do |t|
      t.references :translated, polymorphic: true, index: true
      t.string :language, null: false
      t.jsonb :strings, null: false, default: {}
      t.timestamps
    end
  end
end
