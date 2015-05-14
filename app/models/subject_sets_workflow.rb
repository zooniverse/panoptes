class SubjectSetsWorkflow < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :subject_set

  validates_uniqueness_of :workflow_id, scope: :subject_set_id

  before_destroy :remove_from_queues

  def remove_from_queues
    QueueRemovalWorker.perform_async(subject_set.set_member_subjects.pluck(:id),
                                    workflow_id)
  end
end
