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

  sidekiq_options queue: :data_medium, lock: :until_executing

  def perform(project_id)
    @project = Project.find(project_id)
    Project.transaction do
      project_workflows = project.workflows.select(
        :id,
        :real_set_member_subjects_count,
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
    return 0.0 if no_active_workflows? || no_linked_subjects?

    # return the sum of the proportional completeness metrics
    project.active_workflows.sum(0.0) do |active_workflow|
      # as each workflow has a proportion of the total subjects
      # we can weight each workflow's completeness metric to the total for the project
      subject_proportion = active_workflow.subjects_count.to_f / project_subjects_count

      # the summated proportion metrics will be clamped to the 0.0..1.0 range by subjects / total subjects fraction
      active_workflow.completeness * subject_proportion
    end
  end

  def workflow_completeness(workflow)
    workflow_subjects_count = workflow.subjects_count

    return 0.0 if workflow_subjects_count.zero?

    retired_subjects = workflow.retired_subjects_count
    total_subjects = workflow_subjects_count
    (0.0..1.0).clamp(retired_subjects / total_subjects.to_f)
  end

  def project_columns_to_update
    completeness = project_completeness.to_d
    columns_to_update = { completeness: completeness }

    # avoid the overriden project.finished? method
    return columns_to_update if project.state == 'finished'

    if completeness.to_i == 1 || no_active_workflows? || no_linked_subjects?
      columns_to_update[:state] = Project.states[:paused]
    elsif project.paused?
      columns_to_update[:state] = Project.states[:active]
    end

    columns_to_update
  end

  def no_active_workflows?
    @no_active_workflows ||= project.active_workflows.empty?
  end

  def project_subjects_count
    @project_subjects_count ||= project.active_workflows.sum(&:subjects_count)
  end

  def no_linked_subjects?
    @no_linked_subjects ||= project_subjects_count.zero?
  end
end
