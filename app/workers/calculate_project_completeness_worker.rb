require 'retirement_schemes'

class CalculateProjectCompletenessWorker
  include Sidekiq::Worker
  using Refinements::RangeClamping

  sidekiq_options queue: :data_medium

  def perform(project_id)
    project = Project.find(project_id)
    Project.transaction do
      project.workflows.each do |workflow|
        workflow.update_columns completeness: workflow_completeness(workflow)
      end
      project.update_columns completeness: project_completeness(project)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def project_completeness(project)
    completenesses = project.active_workflows.map(&:completeness)
    completenesses.sum / completenesses.size.to_f
  end

  def workflow_completeness(workflow)
    workflow_subjects_count = workflow.subjects_count

    if workflow_subjects_count == 0
      0.0
    else
      retired_subjects = workflow.retired_subjects_count
      total_subjects = workflow_subjects_count
      (0.0..1.0).clamp(retired_subjects / total_subjects.to_f)
    end
  end
end
