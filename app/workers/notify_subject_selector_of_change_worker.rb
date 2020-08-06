class NotifySubjectSelectorOfChangeWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, dead: false, queue: :data_high

  def perform(workflow_id)
    workflow = Workflow.find_without_json_attrs(workflow_id)
    workflow.subject_selector.reload_workflow
  rescue ActiveRecord::RecordNotFound
  end
end
