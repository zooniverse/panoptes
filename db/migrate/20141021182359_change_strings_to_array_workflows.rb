class ChangeStringsToArrayWorkflows < ActiveRecord::Migration
  def change
    remove_column :workflow_contents, :strings, :json
    add_column :workflow_contents, :strings, :string, array: true, null: false, default: []
  end
end
