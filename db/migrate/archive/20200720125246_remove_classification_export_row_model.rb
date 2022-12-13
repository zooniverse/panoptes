class RemoveClassificationExportRowModel < ActiveRecord::Migration
  def change
    drop_table :classification_export_rows do
    end
  end
end
