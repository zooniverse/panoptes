class ForeignKeysSubjectQueues < ActiveRecord::Migration
  def change
    SubjectQueue.joins("LEFT OUTER JOIN subject_sets ON subject_sets.id = subject_queues.subject_set_id").where("subject_queues.subject_set_id IS NOT NULL AND subject_sets.id IS NULL").delete_all
    SubjectQueue.joins("LEFT OUTER JOIN workflows ON workflows.id = subject_queues.workflow_id").where("subject_queues.workflow_id IS NOT NULL AND workflows.id IS NULL").delete_all
    SubjectQueue.joins("LEFT OUTER JOIN users ON users.id = subject_queues.user_id").where("subject_queues.user_id IS NOT NULL AND users.id IS NULL").delete_all
    add_foreign_key :subject_queues, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :subject_queues, :workflows, on_update: :cascade, on_delete: :cascade
    add_foreign_key :subject_queues, :subject_sets, on_update: :cascade, on_delete: :restrict
  end
end
