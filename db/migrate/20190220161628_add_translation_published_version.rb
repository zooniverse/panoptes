class AddTranslationPublishedVersion < ActiveRecord::Migration
  def change
    add_column :translations, :published_version_id, :integer, null: true
    add_foreign_key :translations, :translation_versions, column: :published_version_id
  end
end
