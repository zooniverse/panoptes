class AddProjectActivity < ActiveRecord::Migration
  def change
    add_column :projects, :activity, :integer, null: false, default: 0
    add_column :workflows, :activity, :integer, null: false, default: 0
  end
end
