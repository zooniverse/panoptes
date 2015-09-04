class DequeueSubjectQueueWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(workflow_id, sms_ids, user_id=nil, subject_set_id=nil)
    workflow = Workflow.find(workflow_id)
    user = User.find(user_id) if user_id
    unless sms_ids.blank?
      SubjectQueue.dequeue(workflow, sms_ids, user: user, set_id: subject_set_id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
