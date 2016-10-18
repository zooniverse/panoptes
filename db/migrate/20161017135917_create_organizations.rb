class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :display_name
      t.string :slug, default: ""
      t.string :primary_language, null: false
      t.timestamp :listed_at, default: nil

      t.timestamps null: false
    end
  end
end
