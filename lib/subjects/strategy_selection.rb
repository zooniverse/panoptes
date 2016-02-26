require 'subjects/cellect_client'
require 'subjects/postgresql_selection'
require 'subjects/seen_remover'

module Subjects
  class StrategySelection
    attr_reader :workflow, :user, :subject_set_id, :limit, :strategy_param

    def initialize(workflow, user, set_id, limit=SubjectQueue::DEFAULT_LENGTH, strategy_param=nil)
      @workflow = workflow
      @user = user
      @subject_set_id = subject_set_id
      @limit = limit
      @strategy_param = strategy_param
    end

    def select
      sms_ids = strategy_sms_ids.compact
      if sms_ids.empty?
        []
      else
        Subjects::SeenRemover.new(user_seen_subject, sms_ids).unseen_ids
      end
    rescue Subjects::CellectClient::ConnectionError
      default_strategy_sms_ids
    end

    def strategy
      @strategy ||= case
      when !Panoptes.cellect_on
        nil
      when strategy_param == :cellect
        strategy_param
      else
        workflow_strategy
      end
    end

    private

    def strategy_sms_ids
      case strategy
      when :cellect
        cellect_params = [ workflow.id, user.try(:id), subject_set_id, limit ]
        subject_ids = Subjects::CellectClient.get_subjects(*cellect_params)
        sms_scope = SetMemberSubject.by_subject_workflow(subject_ids, workflow.id)
        sms_scope.pluck("set_member_subjects.id")
      else
        default_strategy_sms_ids
      end
    end

    def default_strategy_sms_ids
      opts = { limit: limit, subject_set_id: subject_set_id }
      Subjects::PostgresqlSelection.new(workflow, user, opts).select
    end

    def workflow_strategy
      if set_strategy = workflow.selection_strategy
        set_strategy
      elsif workflow.using_cellect?
        :cellect
      end
    end

    def user_seen_subject
      if user
        UserSeenSubject.find_by(user: user, workflow: workflow)
      end
    end
  end
end
