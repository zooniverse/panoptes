class NotifySubjectSelectorOfRetirementWorker
  include Sidekiq::Worker

  # SGL-PRIORITY
  # sidekiq_options retry: 3, queue: :data_high
  sidekiq_options retry: 3, queue: :high

  def perform(subject_id, workflow_id)
    workflow = Workflow.find(workflow_id)
    workflow.subject_selector.remove_subject(subject_id)
  rescue ActiveRecord::RecordNotFound
  end
end
