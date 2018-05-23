class RetireSubjectWorker
  include Sidekiq::Worker
  attr_reader :workflow

  sidekiq_options queue: :high

  def perform(workflow_id, subject_ids, reason=nil)
    begin
      @workflow = Workflow.find(workflow_id)
    rescue ActiveRecord::RecordNotFound
      return nil
    end

    Array.wrap(subject_ids).each do |subject_id|
      count = subject_workflow_status(subject_id)
      RetirementWorker.perform_async(count.id, reason)
    end
  end

  private

  def subject_workflow_status(subject_id)
    workflow
    .subject_workflow_statuses
    .where(subject_id: subject_id)
    .first_or_create!
  end
end
