class RemoveEnqueuedFromClassification < ActiveRecord::Migration
  def change
    remove_column :classifications, :enqueued, :boolean
  end
end
