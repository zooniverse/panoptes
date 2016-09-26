require 'subjects/cellect_client'
require 'subjects/postgresql_selection'
require 'subjects/seen_remover'

module Subjects
  class StrategySelection
    attr_reader :workflow, :user, :subject_set_id, :limit, :strategy_param

    def initialize(workflow, user, subject_set_id, limit=SubjectQueue::DEFAULT_LENGTH, strategy_param=nil)
      @workflow = workflow
      @user = user
      @subject_set_id = subject_set_id
      @limit = limit
      @strategy_param = strategy_param
    end

    def select
      selected_ids = select_sms_ids.compact
      unseen_ids = strip_seen_ids(selected_ids)
      strip_retired_ids(unseen_ids)
    end

    def strategy
      @strategy ||= case
      when cellect_strategy?
        :cellect
      when cellect_ex_strategy?
        :cellect_ex
      else
        nil
      end
    end

    private

    def select_sms_ids
      strategy_sms_ids
    rescue Subjects::CellectClient::ConnectionError, CellectExClient::GenericError
      default_strategy_sms_ids
    end

    def cellect_strategy?
      return nil unless Panoptes.flipper.enabled?("cellect")
      strategy_param == :cellect || workflow.using_cellect?
    end

    def cellect_ex_strategy?
      return nil unless Panoptes.flipper.enabled?("cellect_ex")
      strategy_param == :cellect_ex || workflow.subject_selection_strategy == 'cellect_ex'
    end

    def strategy_sms_ids
      case strategy
      when :cellect
        run_cellection do |params|
          Subjects::CellectClient.get_subjects(*params)
        end
      when :cellect_ex
        run_cellection do |params|
          Subjects::CellectExSelection.get_subjects(*params)
        end
      else
        default_strategy_sms_ids
      end
    end

    def default_strategy_sms_ids
      opts = { limit: limit, subject_set_id: subject_set_id }
      Subjects::PostgresqlSelection.new(workflow, user, opts).select
    end

    def strip_seen_ids(sms_ids)
      if !sms_ids.empty? && user
        uss = UserSeenSubject.find_by(user: user, workflow: workflow)
        Subjects::SeenRemover.new(uss, sms_ids).unseen_ids
      else
        sms_ids
      end
    end

    def strip_retired_ids(sms_ids)
      return sms_ids if sms_ids.empty?
      retired_ids = SetMemberSubject
        .retired_for_workflow(workflow)
        .where(set_member_subjects: {id: sms_ids})
        .pluck(:id)
      sms_ids - retired_ids
    end

    def run_cellection
      cellect_params = [ workflow.id, user.try(:id), subject_set_id, limit ]
      subject_ids = yield cellect_params
      sms_scope = SetMemberSubject.by_subject_workflow(subject_ids, workflow.id)
      sms_scope.pluck("set_member_subjects.id")
    end
  end
end
