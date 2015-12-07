class AddCompletenessToProject < ActiveRecord::Migration
  def change
    add_column :projects, :completeness, :float, null: false, default: 0.0
    add_column :workflows, :completeness, :float, null: false, default: 0.0
  end
end
