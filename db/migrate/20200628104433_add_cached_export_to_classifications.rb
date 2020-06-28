class AddCachedExportToClassifications < ActiveRecord::Migration
  def change
    add_reference(:classifications, :cached_export, index: false)
  end
end
