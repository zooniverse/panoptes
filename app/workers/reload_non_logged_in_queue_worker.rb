class ReloadNonLoggedInQueueWorker
  include Sidekiq::Worker

  attr_reader :workflow

  def perform(workflow_id, subject_set_id=nil)
    @workflow = Workflow.find(workflow_id)
    queue_subject_set = workflow.grouped ? subject_set_id : nil
    subjects = PostgresqlSelection.new(workflow, nil)
      .select(limit: SubjectQueue::DEFAULT_LENGTH, subject_set_id: queue_subject_set)
      .compact
    SubjectQueue.reload(workflow, subjects, set_id: queue_subject_set)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
