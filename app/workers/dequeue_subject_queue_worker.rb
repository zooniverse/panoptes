class DequeueSubjectQueueWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  sidekiq_options congestion: { interval: 30, max_in_interval: 1, min_delay: 0, reject_with: :cancel }.merge({
    key: ->(workflow_id, sms_ids, user_id, subject_set_id) {
      "user_#{ workflow_id }_#{user_id}_#{subject_set_id}_subject_enqueue"
    }
  })

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
