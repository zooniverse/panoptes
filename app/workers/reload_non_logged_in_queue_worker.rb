require 'subjects/postgresql_selection'

class ReloadNonLoggedInQueueWorker
  include Sidekiq::Worker

  # SGL-PRIORITY
  # sidekiq_options queue: :data_high
  sidekiq_options queue: :high

  attr_reader :workflow, :subject_set_id

  def perform(workflow_id, set_id=nil)
    @workflow = Workflow.find(workflow_id)
    @subject_set_id = workflow.grouped ? set_id : nil
    if non_logged_in_queue
      ids = selected_subject_ids
      non_logged_in_queue.update_ids(ids) unless ids.empty?
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  def selected_subject_ids
    opts = { limit: SubjectQueue::DEFAULT_LENGTH, subject_set_id: subject_set_id }
    Subjects::PostgresqlSelection.new(workflow, nil, opts).select.compact
  end

  def non_logged_in_queue
    @non_logged_in_queue ||= SubjectQueue.by_set(subject_set_id)
      .find_by(workflow: workflow, user: nil)
  end
end
