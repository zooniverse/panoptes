class AddClassifiersCountToProject < ActiveRecord::Migration
  def change
    add_column :projects, :classifiers_count, :integer, default: 0
  end
end
