class AddLifecycledAtToClassifications < ActiveRecord::Migration
  def change
    add_column :classifications, :lifecycled_at, :timestamp, index: true
  end
end
