class AddSubjectSetIdToUniqueSubjectQueueIndex < ActiveRecord::Migration
  def change
    remove_index :subject_queues, [:user_id, :workflow_id]
    add_index :subject_queues, [:subject_set_id, :workflow_id, :user_id], name: "idx_queues_on_ssid_wid_and_id", unique: true
    add_index :subject_queues, [:workflow_id, :user_id]
  end
end
