class CreateRecents < ActiveRecord::Migration
  def change
    create_table :recents do |t|
      t.references :classification, index: true, foreign_key: true
      t.references :subject, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
