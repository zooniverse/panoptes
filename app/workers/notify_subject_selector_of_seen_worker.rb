class NotifySubjectSelectorOfSeenWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, queue: :data_high

  def perform(workflow_id, user_id, subject_id)
    return if user_id.nil?

    workflow = Workflow.find_without_json_attrs(workflow_id)
    workflow.subject_selector.add_seen(user_id, subject_id)
  rescue ActiveRecord::RecordNotFound
  end
end
