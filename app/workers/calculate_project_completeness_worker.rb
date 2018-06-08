require 'retirement_schemes'

class CalculateProjectCompletenessWorker
  include Sidekiq::Worker
  using Refinements::RangeClamping
  attr_reader :project

  sidekiq_options congestion: {
    interval: 300,
    max_in_interval: 1,
    min_delay: 300,
    reject_with: :cancel,
    key: ->(project_id) {
      "calc_project_completeness_worker#{project_id}"
    }
  }

  sidekiq_options queue: :data_medium, unique: :until_executed

  def perform(project_id)
    @project = Project.find(project_id)
    Project.transaction do
      project_workflows = project.workflows.select(
        :id,
        :retired_set_member_subjects_count
      )
      project_workflows.each do |workflow|
        workflow.update_columns completeness: workflow_completeness(workflow)
      end

      project.update_columns(project_columns_to_update)
      project.touch
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def project_completeness
    return 0.0 if project.active_workflows.empty?

    completenesses = project.active_workflows.pluck(:completeness)
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

  def project_columns_to_update
    completeness = project_completeness
    columns_to_update = { completeness: completeness }

    # avoid the overriden project.finished? method
    if project.state == "finished"
      return columns_to_update
    end

    if completeness.to_i == 1
      columns_to_update[:state] = Project.states[:paused]
    elsif project.paused?
      columns_to_update[:state] = Project.states[:active]
    end

    columns_to_update
  end
end
