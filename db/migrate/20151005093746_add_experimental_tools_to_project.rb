class AddExperimentalToolsToProject < ActiveRecord::Migration
  def change
    add_column :projects, :experimental_tools, :string, array: true, default: []
  end
end
