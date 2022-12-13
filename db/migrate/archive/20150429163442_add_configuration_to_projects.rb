class AddConfigurationToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :configuration, :jsonb
    add_column :projects, :approved, :boolean, index: true
    add_column :projects, :beta, :boolean, index: true
  end
end
