# frozen_string_literal: true

class UnretireSubjectWorker
  include Sidekiq::Worker
  attr_reader :workflow_id

  sidekiq_options queue: :high

  def perform(workflow_id, subject_ids)
    @workflow_id = workflow_id
    return unless workflow_exists?

    SubjectWorkflowStatus.where.not(retired_at: nil).where(workflow_id: workflow_id, subject_id: subject_ids).update_all(retired_at: nil,
                                                                                                                         retirement_reason: nil)
    RefreshWorkflowStatusWorker.perform_async(workflow_id)
    NotifySubjectSelectorOfChangeWorker.perform_async(workflow_id)
  end

  private

  def workflow_exists?
    Workflow.exists?(id: workflow_id)
  end
end
