class NotifySubjectSelectorOfChangeWorker
  include Sidekiq::Worker

  # SGL-PRIORITY
  # sidekiq_options retry: 3, queue: :data_high
  sidekiq_options retry: 3, queue: :high

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    workflow.subject_selector.reload_workflow
  rescue ActiveRecord::RecordNotFound
  end
end
