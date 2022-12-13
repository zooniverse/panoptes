class CreateOrganizationPageVersions < ActiveRecord::Migration
  def change
    create_table :organization_page_versions do |t|
      t.references :organization_page, index: true, foreign_key: true, null: false
      t.text :title
      t.text :content
      t.string :url_key

      t.timestamps null: false
    end
  end
end
