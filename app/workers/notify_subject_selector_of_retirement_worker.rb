class NotifySubjectSelectorOfRetirementWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, dead: false, queue: :data_high

  def perform(subject_id, workflow_id)
    workflow = Workflow.find_without_json_attrs(workflow_id)
    workflow.subject_selector.remove_subject(subject_id)
  rescue ActiveRecord::RecordNotFound
  end
end
