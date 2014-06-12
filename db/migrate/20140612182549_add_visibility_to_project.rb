class AddVisibilityToProject < ActiveRecord::Migration
  def change
    add_column :projects, :visibility, :string, default: 'dev', null: false
  end
end
