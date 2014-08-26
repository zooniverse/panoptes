class AddVisibleToToProject < ActiveRecord::Migration
  def change
    add_column :projects, :visible_to, :string, array: true, default: [], null: false
  end
end
