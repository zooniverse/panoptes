require 'subjects/cellect_client'

class EnqueueSubjectQueueWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  sidekiq_options congestion: Panoptes::SubjectEnqueue.congestion_opts.merge({
    key: ->(workflow_id, user_id, subject_set_id) {
      "user_#{ workflow_id }_#{user_id}_#{subject_set_id}_subject_enqueue"
    }
  })

  attr_reader :workflow, :user, :subject_set_id, :limit, :selection_strategy

  def perform(workflow_id, user_id=nil, subject_set_id=nil, limit=SubjectQueue::DEFAULT_LENGTH, strategy_override=nil)
    @workflow = Workflow.find(workflow_id)
    @user = User.find(user_id) if user_id
    @subject_set_id = subject_set_id
    @limit = limit
    @selection_strategy = strategy(strategy_override)

    begin
      subject_ids = selected_subject_ids.compact
    rescue Subjects::CellectClient::ConnectionError
      subject_ids = default_strategy_sms_ids
    end

    unless subject_ids.empty?
      SubjectQueue.enqueue(workflow, subject_ids, user: user, set_id: subject_set_id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def strategy(requested)
    return nil unless Panoptes.cellect_on
    return requested if requested == :cellect
    case
    when workflow_strategy
      workflow_strategy
    when workflow.using_cellect?
       :cellect
    end
  end

  private

  def selected_subject_ids
    sms_ids = case selection_strategy
    when :cellect
      cellect_params = [ workflow.id, user.try(:id), subject_set_id, limit ]
      subject_ids = Subjects::CellectClient.get_subjects(*cellect_params)
      sms_scope = SetMemberSubject.by_subject_workflow(subject_ids, workflow.id)
      sms_scope.pluck("set_member_subjects.id")
    else
      default_strategy_sms_ids
    end
    Array.wrap(sms_ids)
  end

  def default_strategy_sms_ids
    opts = { limit: limit, subject_set_id: subject_set_id }
    Subjects::PostgresqlSelection.new(workflow, user, opts).select
  end

  def workflow_strategy
    @workflow_strategy ||= workflow.selection_strategy
  end
end
