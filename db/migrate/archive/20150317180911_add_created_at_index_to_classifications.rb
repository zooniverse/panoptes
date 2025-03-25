class AddCreatedAtIndexToClassifications < ActiveRecord::Migration
  def change
    add_index :classifications, :created_at
  end
end
