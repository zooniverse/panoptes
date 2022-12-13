class AddTranslationVersions < ActiveRecord::Migration
  def change
    create_table :translation_versions do |t|
      t.references :translation, foreign_key: true, null: false
      t.jsonb :strings
      t.jsonb :string_versions
      t.timestamps
    end

    add_index :translation_versions, :translation_id
  end
end
