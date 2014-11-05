class AddMetadataToClassifications < ActiveRecord::Migration
  def change
    add_column :classifications, :metadata, :json, default: {}, null: false
  end
end
