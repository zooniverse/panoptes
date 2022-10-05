# frozen_string_literal: true

class CalculateProjectCompletenessWorker
  include Sidekiq::Worker
  using Refinements::RangeClamping
  attr_reader :project

  COMPLETENESS_ROUNDING_PRECISION = ENV.fetch('COMPLETENESS_ROUNDING_PRECISION', 4).to_i

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
    proportional_completeness = project.active_workflows.sum do |active_workflow|
      # as each workflow has a proportion of the total subjects
      # we can weight each workflow's completeness metric to the total for the project
      subject_proportion = active_workflow.subjects_count.to_f / project_subjects_count
      active_workflow.completeness * subject_proportion
    end

    # avoid the loss of precision for small / recurring float values
    # that under certain conditions can cause the per workflow subject_proportion values not to summate to 1.0
    # that in turn cause the project completion metric not to summate to 1.0
    #
    # this due to the loss of precision when doing floating point calculations
    # even with the use of the BigDecimal library as some recurring values fail with this class
    #
    # round the summated values to the desired significant digits
    # to avoid the loss of precision on this metric calculation
    proportional_completeness.round(COMPLETENESS_ROUNDING_PRECISION)
  end

  def workflow_completeness(workflow)
    workflow_subjects_count = workflow.subjects_count

    return 0.0 if workflow_subjects_count.zero?

    retired_subjects = workflow.retired_subjects_count
    total_subjects = workflow_subjects_count
    (0.0..1.0).clamp(retired_subjects / total_subjects.to_d)
  end

  def project_columns_to_update
    completeness = project_completeness
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
