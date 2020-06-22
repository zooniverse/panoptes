class AddPolymorphicCachedExportResource < ActiveRecord::Migration
  def change
    create_table :cached_export do |t|
      t.references :resource, polymorphic: true, null: false
      t.string :format, null: false
      t.jsonb :export_data, null: false
      t.timestamps
    end

    # add unique case-insensitive compound index on linked resource (id/type) and the format, e.g csv
    add_index :cached_export, %i[resource_id resource_type format], unique: true, case_sensitive: false
  end
end
