# frozen_string_literal: true

class UnretireSubjectWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(workflow_id, subject_ids)
    return unless  Workflow.exists?(id: workflow_id)

    SubjectWorkflowStatus.where.not(retired_at: nil).where(workflow_id: workflow_id, subject_id: subject_ids).update_all(retired_at: nil,
                                                                                                                         retirement_reason: nil)
    RefreshWorkflowStatusWorker.perform_async(workflow_id)
    NotifySubjectSelectorOfChangeWorker.perform_async(workflow_id)
  end
end
