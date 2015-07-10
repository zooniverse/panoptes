class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.text :name, null: false
      t.integer :tagged_resources_count, default: 0

      t.timestamps null: false
    end

    create_table :tagged_resources do |t|
      t.references :resource, polymorphic: true, index: true
      t.references :tag, index: true, foreign_key: true
    end

    add_index :tags, :name, unique: true
    add_index :tags, :name, operator_class: "gin_trgm_ops", using: :gin, name: "tags_name_trgm_idx"
  end
end
