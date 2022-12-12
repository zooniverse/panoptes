class AddIndexToRetiredWorkflows < ActiveRecord::Migration
  def change
    unless index_exists?(:set_member_subjects, :retired_workflow_ids)
      add_index :set_member_subjects, :retired_workflow_ids, using: :gin
    end
  end
end
