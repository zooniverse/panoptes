class WorkflowRetiredCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  sidekiq_options congestion: {
    interval: 10,
    max_in_interval: 1,
    min_delay: 10,
    reject_with: :reschedule,
    key: ->(workflow_id) { "workflow_#{workflow_id}_retired_count_worker" }
  }

  sidekiq_options unique: :until_executed

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    counter = WorkflowCounter.new(workflow)
    workflow.update_column(
      :retired_set_member_subjects_count,
      counter.retired_subjects
    )

    if workflow.finished_at.nil? && workflow.finished?
      Workflow.where(id: workflow.id).update_all(finished_at: Time.now)
    end
  end
end
