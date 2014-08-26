class AddCompletedToClassifications < ActiveRecord::Migration
  def change
    add_column :classifications, :completed, :boolean
  end
end
