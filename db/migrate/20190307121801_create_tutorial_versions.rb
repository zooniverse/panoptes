class CreateTutorialVersions < ActiveRecord::Migration
  def change
    create_table :tutorial_versions do |t|
      t.references :tutorial, index: true, foreign_key: true, null: false
      t.json :steps
      t.string :kind
      t.text :display_name

      t.timestamps null: false
    end
  end
end
