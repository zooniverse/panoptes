class CreateTutorials < ActiveRecord::Migration
  def change
    create_table :tutorials do |t|
      t.json :steps, default: []
      t.text :language, index: true
      t.references :workflow, index: true

      t.timestamps null: false
    end
  end
end
