class WorkflowRetiredCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :subject_set_id

  def perform(subject_set_id)
    @subject_set_id = subject_set_id
    reset_retired_subject_counter
  end

  private

  def reset_retired_subject_counter
    subject_set_workflows.find_each do |w|
      w.update_column(
        :retired_set_member_subjects_count,
        retired_counts_since_launch(w)
      )
    end
  end

  def subject_set_workflows
    Workflow.joins(:subject_sets).where(subject_sets: {id: subject_set_id})
  end

  def retired_counts_since_launch(workflow)
    project = workflow.project
    swcs = SubjectWorkflowCount
      .retired
      .by_set(subject_set_id)
      .where(workflow_id: workflow.id)
    if project.launch_date
      swcs = swcs.where("subject_workflow_counts.created_at >= ?", project.launch_date)
    end
    swcs.count
  end
end
