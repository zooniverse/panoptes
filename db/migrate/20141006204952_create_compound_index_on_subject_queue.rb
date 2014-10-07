class CreateCompoundIndexOnSubjectQueue < ActiveRecord::Migration
  def change
    remove_index :user_subject_queues, column: :user_id
    remove_index :user_subject_queues, column: :workflow_id
    add_index :user_subject_queues, [:user_id, :workflow_id], unique: true
  end
end
