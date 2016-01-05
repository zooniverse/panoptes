class ReloadNonLoggedInQueueWorker
  include Sidekiq::Worker

  attr_reader :workflow

  def perform(workflow_id, subject_set_id=nil)
    @workflow = Workflow.find(workflow_id)
    subject_set_id = workflow.grouped ? subject_set_id : nil
    subject_ids = selected_subject_ids(workflow, subject_set_id).compact
    unless subject_ids.empty?
      SubjectQueue.reload(workflow, subject_ids, set_id: subject_set_id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  def selected_subject_ids(workflow, subject_set_id)
    opts = { limit: SubjectQueue::DEFAULT_LENGTH, subject_set_id: subject_set_id }
    Subjects::PostgresqlSelection.new(workflow, nil, opts).select
  end
end
