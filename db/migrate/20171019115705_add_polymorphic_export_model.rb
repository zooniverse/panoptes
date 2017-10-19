class AddPolymorphicExportModel < ActiveRecord::Migration
  def change
    create_table :exports do |t|
      t.references :exportable, polymorphic: true, index: true
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end
  end
end
