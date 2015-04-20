class SubjectQueueWorker
  include Sidekiq::Worker

  attr_reader :workflow, :user, :limit

  def perform(workflow, user: nil, limit: SubjectQueue::DEFAULT_LENGTH)
    @workflow = Workflow.find(workflow)
    @user = User.find(user) if user
    @limit = limit

    if workflow.grouped
      workflow.subject_sets.each do |set|
        load_subjects(set.id)
      end
    else
      load_subjects
    end
  end

  def load_subjects(set=nil)
    subject_ids = PostgresqlSelection.new(workflow, user)
                  .select(limit: limit, subject_set_id: set)

    SubjectQueue.enqueue(workflow, subject_ids, user: user, set: set)
  end
end
