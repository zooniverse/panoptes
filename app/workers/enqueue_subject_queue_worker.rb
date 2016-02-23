require 'subjects/cellect_client'
require 'subjects/postgresql_selection'
require 'subjects/seen_remover'

class EnqueueSubjectQueueWorker
  include Sidekiq::Worker

  sidekiq_options queue: :really_high

  sidekiq_options congestion: Panoptes::SubjectEnqueue.congestion_opts.merge({
    key: ->(queue_id) {
      "queue_#{ queue_id }_enqueue"
    }
  })

  attr_reader :queue, :workflow, :user, :subject_set_id, :limit, :selection_strategy

  def perform(queue_id, limit=SubjectQueue::DEFAULT_LENGTH, strategy_override=nil)
    # @note REVERT after https://github.com/zooniverse/Panoptes/pull/1676 is deployed
    return nil if Rails.env.production?
    @queue = SubjectQueue.find(queue_id)
    @workflow = queue.workflow
    @user = queue.user
    @subject_set_id = queue.subject_set_id
    @limit = limit
    @selection_strategy = strategy(strategy_override)

    sms_ids = strategy_sms_ids
    unless sms_ids.empty?
      unseen_ids = Subjects::SeenRemover.new(user, workflow, sms_ids).unseen_ids
      queue.enqueue_update(unseen_ids)
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

  def selected_sms_ids
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

  def strategy_sms_ids
    selected_sms_ids.compact
  rescue Subjects::CellectClient::ConnectionError
    default_strategy_sms_ids
  end
end
