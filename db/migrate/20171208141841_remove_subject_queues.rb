class RemoveSubjectQueues < ActiveRecord::Migration
  def change
    drop_table :subject_queues
  end
end
