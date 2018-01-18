class AddUniqueTranslatedLangaugeIndex < ActiveRecord::Migration
  def change
    Translation.update_all("language = lower(language)")

    table_name = :translations
    index_cols = %i(translated_type translated_id)

    if index_exists?(table_name, index_cols)
      remove_index table_name, column: index_cols
    end

    if index_exists?(table_name, :language)
      remove_index table_name, column: :language
    end

    index_name = 'idx_translations_on_translated_type+id_and_language'
    add_index table_name, index_cols | %i(language), unique: true, name: index_name
  end
end
