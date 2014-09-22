class AddStateToClassifications < ActiveRecord::Migration
  def change
    remove_column :classifications, :completed, :boolean
    add_column :classifications, :state, :integer, default: 0, null: false
  end
end
