class ModifySubjectSetQueuesFkConstraint < ActiveRecord::Migration
  def change
    remove_foreign_key :subject_queues, :subject_sets
    add_foreign_key :subject_queues, :subject_sets, on_update: :cascade, on_delete: :cascade
  end
end
