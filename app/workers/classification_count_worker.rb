class ClassificationCountWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: :high, retry: 3

  def perform(subject_id, workflow_id)
    SetMemberSubject.by_subject_workflow(subject_id, workflow_id).each do |sms|
      sms.update!(classification_count: sms.classification_count + 1)
      RetirementWorker.perform_async(sms.id, workflow_id)
    end
  end
end
