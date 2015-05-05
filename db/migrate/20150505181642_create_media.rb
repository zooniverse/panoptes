class CreateMedia < ActiveRecord::Migration
  def change
    create_table :media do |t|
      t.string :type, index: true
      t.references :linked, polymorphic: true, index: true
      t.string :content_type
      t.text :src
      t.text :path_opts, array: true

      t.timestamps null: false
    end
  end
end
