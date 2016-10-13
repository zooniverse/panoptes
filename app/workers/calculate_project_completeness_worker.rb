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
    return 0.0 if workflow.subjects.count == 0

    case workflow.retirement_scheme
      when RetirementSchemes::NeverRetire
        total_subjects = workflow.subjects.count
        retired_subjects = workflow.retired_subjects_count

        (0.0..1.0).clamp(retired_subjects / total_subjects.to_f)
    when RetirementSchemes::ClassificationCount
      total_subjects = workflow.subjects.count
      classifications_needed = total_subjects * workflow.retirement_scheme.count
      classifications_made = workflow.classifications_count

      (0.0..1.0).clamp(classifications_made / classifications_needed.to_f)
    else
      0.0
    end
  end
end
