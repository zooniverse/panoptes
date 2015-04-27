class AddIndexToRetiredWorkflows < ActiveRecord::Migration
  def change
    add_index :set_member_subjects, :retired_workflow_ids, using: :gin
  end
end
