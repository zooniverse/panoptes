class AddFeaturedToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :featured, :boolean, default: false, null: false, index: true
  end
end
