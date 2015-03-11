class ClassificationCountWorker
  include Sidekiq::Worker
  
  def perform(subject_id, workflow_id)
    SetMemberSubject.by_subject_workflow(subject_id, workflow_id).each do |sms|
      SetMemberSubject.increment_counter(:classification_count, sms.id)
      RetirementWorker.perform_async(sms.id, workflow_id)
    end
  end
end
