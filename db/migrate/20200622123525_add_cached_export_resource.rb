class AddCachedExportResource < ActiveRecord::Migration
  def change
    create_table :cached_exports do |t|
      t.integer :resource_id, null: false
      t.string :resource_type, null: false
      t.jsonb :data, null: false
      t.timestamps
    end
  end
end
