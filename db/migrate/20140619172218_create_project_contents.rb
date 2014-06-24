class CreateProjectContents < ActiveRecord::Migration
  def change
    create_table :project_contents do |t|
      t.references :project, index: true
      t.string :language
      t.string :title
      t.text :description
      t.json :pages
      t.json :example_strings

      t.timestamps
    end
  end
end
