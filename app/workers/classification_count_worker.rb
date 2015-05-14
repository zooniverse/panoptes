class ClassificationCountWorker
  include Sidekiq::Worker

  def perform(subject_id, workflow_id)
    if Workflow.find(workflow_id).project.live
      SetMemberSubject.by_subject_workflow(subject_id, workflow_id).find_each do |sms|
        count = SubjectWorkflowCount.find_or_create_by!(set_member_subject_id: sms.id, workflow_id: workflow_id)
        SubjectWorkflowCount.increment_counter(:classifications_count, count.id)
        RetirementWorker.perform_async(count.id)
      end
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
