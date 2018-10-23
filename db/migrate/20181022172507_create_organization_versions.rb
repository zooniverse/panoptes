class CreateOrganizationVersions < ActiveRecord::Migration
  def change
    create_table :organization_versions do |t|
      t.references :organization, index: true, foreign_key: true, null: false
      t.string :display_name
      t.string :description
      t.text :introduction
      t.jsonb :urls
      t.jsonb :url_labels
      t.string :announcement

      t.timestamps null: false
    end
  end
end
