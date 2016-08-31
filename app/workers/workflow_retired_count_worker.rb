class WorkflowRetiredCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :workflow

  def perform(workflow_id)
    @workflow = Workflow.find(workflow_id)
    workflow.update_column(
      :retired_set_member_subjects_count,
      retired_counts_since_launch(workflow.project.launch_date)
    )
  end

  private

  def retired_counts_since_launch(launch_date)
    swcs = SubjectWorkflowStatus.retired.where(workflow_id: workflow.id)
    if launch_date
      swcs = swcs.where("subject_workflow_counts.created_at >= ?", launch_date)
    end
    swcs.count
  end
end
