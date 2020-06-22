class AddPolymorphicCachedExportResource < ActiveRecord::Migration
  def change
    create_table :cached_exports do |t|
      t.references :resource, polymorphic: true, null: false
      t.string :format, null: false
      t.jsonb :data, null: false
      t.timestamps
    end

    safety_assured {
      # add unique compound index on linked resource (id/type) and the format e.g csv/json etc
      add_index :cached_exports,
                %i[resource_id resource_type format],
                unique: true,
                name: 'index_cached_exports_on_resource_id_resource_type_and_format'
    }
  end
end
