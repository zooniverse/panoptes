class ConvertArrayDefaultDeclarations < ActiveRecord::Migration
  def change
    change_column :users, :languages, :string, array: true, default: []
    change_column :oauth_applications, :default_scope, :string, array: true, default: []
  end
end
