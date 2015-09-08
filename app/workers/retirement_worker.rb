class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(count_id)
    count = SubjectWorkflowCount.find(count_id)
    if count.retire?
      count.retire! do
        SubjectQueue.where(workflow: count.workflow).find_each do |sq|
          sms_ids = [ count.set_member_subject.id ]
          DequeueSubjectQueueWorker.perform_async(sq.workflow_id, sms_ids, sq.user_id, sq.subject_set_id)
        end
        deactivate_workflow!(count.workflow)
      end
    end
  end

  def deactivate_workflow!(workflow)
    if workflow.finished?
      Workflow.where(id: workflow.id).update_all(active: false)
    end
  end
end
