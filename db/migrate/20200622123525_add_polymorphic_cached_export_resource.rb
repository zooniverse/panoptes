class AddPolymorphicCachedExportResource < ActiveRecord::Migration
  def change
    create_table :cached_exports do |t|
      t.references :resource, polymorphic: true, index: true, null: false
      t.jsonb :data, null: false
      t.timestamps
    end
  end
end
