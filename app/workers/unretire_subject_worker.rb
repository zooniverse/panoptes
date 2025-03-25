# frozen_string_literal: true

class UnretireSubjectWorker
  include Sidekiq::Worker
  attr_reader :workflow_id, :subject_ids

  sidekiq_options queue: :high

  def perform(workflow_id, subject_ids)
    return unless Workflow.exists?(id: workflow_id)
    @workflow_id = workflow_id
    @subject_ids = subject_ids

    unretire_all_known_subjects

    recalculate_subject_set_completion_metrics

    RefreshWorkflowStatusWorker.perform_async(workflow_id)
    NotifySubjectSelectorOfChangeWorker.perform_async(workflow_id)
  end

  private

  def unretire_all_known_subjects
    SubjectWorkflowStatus
      .where.not(retired_at: nil)
      .where(workflow_id: workflow_id, subject_id: subject_ids)
      .update_all(retired_at: nil, retirement_reason: nil)
  end

  def recalculate_subject_set_completion_metrics
    linked_subject_sets.each do |subject_set|
      SubjectSetCompletenessWorker.perform_async(subject_set.id, workflow_id)
    end
  end

  # find all subject sets for all subject_ids in this workflow
  def linked_subject_sets
    SubjectSet
      .joins(:workflows)
      .where(workflows: { id: workflow_id })
      .joins(:set_member_subjects)
      .where(set_member_subjects: { subject_id: subject_ids })
      .select(:id)
      .distinct
  end
end
