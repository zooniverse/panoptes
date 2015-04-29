class ReloadQueueWorker
  include Sidekiq::Worker

  attr_reader :workflow

  def perform(workflow_id)
    @workflow = Workflow.find(workflow_id)
    case
    when workflow.grouped
      workflow.subject_sets.each do |set|
        reload_subjects(set)
      end
    else
      reload_subjects
    end
  end

  def reload_subjects(set=nil)
    subjects = PostgresqlSelection.new(workflow, nil)
      .select(limit: SubjectQueue::DEFAULT_LENGTH, subject_set_id: set)
      .map(&:id)

    SubjectQueue.reload(workflow, subjects, set: set)
  end
end
