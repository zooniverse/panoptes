class WfVersionIndices < ActiveRecord::Migration
  def change
    add_index :workflow_versions, [:workflow_id, :major_number, :minor_number], unique: true, name: "index_workflow_versions_on_workflow_and_major_and_minor"
  end
end
