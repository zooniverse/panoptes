class ReloadNonLoggedInQueueWorker
  include Sidekiq::Worker

  attr_reader :workflow

  def perform(workflow_id, subject_set_id=nil)
    @workflow = Workflow.find(workflow_id)
    subjects = PostgresqlSelection.new(workflow, nil)
      .select(limit: SubjectQueue::DEFAULT_LENGTH, subject_set_id: subject_set_id)
      .compact
    SubjectQueue.reload(workflow, subjects, set_id: subject_set_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
