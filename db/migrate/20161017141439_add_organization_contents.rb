class AddOrganizationContents < ActiveRecord::Migration
  def change
    create_table :organization_contents do |t|
      t.string :title, null: false
      t.string :description, null: false
      t.text :introduction, default: ""
      t.string :language, null: false

      t.references :organization
      t.timestamps null: false
    end

    add_foreign_key :organization_contents, :organizations, on_delete: :cascade
  end
end
