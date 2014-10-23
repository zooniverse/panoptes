class RemovePagesFromProjectContents < ActiveRecord::Migration
  def change
    remove_column :project_contents, :pages, :json
    remove_column :project_contents, :example_strings, :json
  end
end
