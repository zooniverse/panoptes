class RetireSubjectWorker
  include Sidekiq::Worker
  attr_reader :workflow_id

  sidekiq_options queue: :high

  def perform(workflow_id, subject_ids, reason=nil)
    @workflow_id = workflow_id
    if workflow_exists?
      Array.wrap(subject_ids).each do |subject_id|
        count = subject_workflow_status(subject_id)
        RetirementWorker.perform_async(count.id, true, reason)
      rescue ActiveRecord::RecordInvalid
        # need to rescue the error when folks pass in a subject id that doesn't exist
        # but we still keep processing the whole list of subjects we have
      end
    end
  end

  private

  def workflow_exists?
    Workflow.where(id: workflow_id).exists?
  end

  def subject_workflow_status(subject_id)
    SubjectWorkflowStatus
    .where(workflow_id: workflow_id, subject_id: subject_id)
    .first_or_create!
  end
end
