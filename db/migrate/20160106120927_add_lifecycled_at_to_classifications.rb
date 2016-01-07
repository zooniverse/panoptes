class AddLifecycledAtToClassifications < ActiveRecord::Migration
  def change
    add_column :classifications, :lifecycled_at, :timestamp
  end
end
