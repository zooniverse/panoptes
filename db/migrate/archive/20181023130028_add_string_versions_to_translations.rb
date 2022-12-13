class AddStringVersionsToTranslations < ActiveRecord::Migration
  def change
    add_column :translations, :string_versions, :jsonb
    Translation.reset_column_information
    Translation.update_all string_versions: {}
    change_column_default :translations, :string_versions, {}
    change_column_null :translations, :string_versions, false
  end
end
