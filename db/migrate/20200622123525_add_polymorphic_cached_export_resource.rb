class AddPolymorphicCachedExportResource < ActiveRecord::Migration
  def change
    create_table :cached_export do |t|
      t.references :resource, polymorphic: true, null: false
      t.string :format, null: false
      t.jsonb :export_data, null: false
      t.timestamps
    end

    # add unique compound index on linked resource (id/type) and the format e.g csv/json etc
    add_index :cached_export, %i[resource_id resource_type format], unique: true
  end
end
