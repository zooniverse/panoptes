class WorkflowSubjectsCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  sidekiq_options congestion: {
    interval: 60,
    max_in_interval: 1,
    min_delay: 60,
    reject_with: :reschedule,
    key: ->(workflow_id) {
      "workflow_#{workflow_id}_subjects_count_worker"
    }
  }

  sidekiq_options lock: :until_executing

  def perform(workflow_id)
    workflow = Workflow.find_without_json_attrs(workflow_id)
    counter = WorkflowCounter.new(workflow)
    workflow.update_column(:set_member_subjects_count, counter.subjects)
  end
end
