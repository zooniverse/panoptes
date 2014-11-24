class ChangeWorkflowContentStringsFromArraytoJson < ActiveRecord::Migration
  def change
    remove_column :workflow_contents, :strings, :string, array: true, default: [], null: false
    add_column :workflow_contents, :strings, :json, default: {}, null: false
  end
end
