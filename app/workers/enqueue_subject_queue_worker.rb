class EnqueueSubjectQueueWorker
  include Sidekiq::Worker

  attr_reader :workflow, :user

  def perform(workflow_id, user_id=nil, subject_set_id=nil, limit=SubjectQueue::DEFAULT_LENGTH)
    @workflow = Workflow.find(workflow_id)
    @user = User.find(user_id) if user_id

    subject_ids = PostgresqlSelection.new(workflow, user)
      .select(limit: limit, subject_set_id: subject_set_id)
      .compact
    unless subject_ids.empty?
      SubjectQueue.enqueue(workflow, subject_ids, user: user, set_id: subject_set_id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
