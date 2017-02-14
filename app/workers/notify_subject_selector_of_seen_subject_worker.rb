class NotifySubjectSelectorOfSeenSubjectWorker
  include Sidekiq::Worker

  # SGL-PRIORITY
  # sidekiq_options retry: 3, queue: :data_high
  sidekiq_options retry: 3, queue: :high, dead: false

  def perform(workflow_id, user_id, subject_id)
    return if user_id.nil?

    workflow = Workflow.find(workflow_id)
    workflow.subject_selector.add_seen(user_id, subject_id)
  rescue ActiveRecord::RecordNotFound
  end
end
