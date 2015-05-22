class AddMetadataToMedia < ActiveRecord::Migration
  def change
    add_column :media, :metadata, :jsonb
  end
end
