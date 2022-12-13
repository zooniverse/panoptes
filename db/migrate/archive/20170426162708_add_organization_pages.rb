class AddOrganizationPages < ActiveRecord::Migration
  def change
    create_table :organization_pages do |t|
      t.string :url_key
      t.text :title
      t.string :language
      t.text :content
      t.references :organization, index: true

      t.timestamps null: false
    end

    add_index :organization_pages, :language
  end
end
