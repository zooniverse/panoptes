class AddCompletedToClassifications < ActiveRecord::Migration
  def change
    add_column :classifications, :completed, :boolean, default: true, null: false
  end
end
