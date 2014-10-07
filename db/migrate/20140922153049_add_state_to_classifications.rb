class AddStateToClassifications < ActiveRecord::Migration
  def change
    add_column :classifications, :enqueued, :boolean, default: false, null: false
  end
end
