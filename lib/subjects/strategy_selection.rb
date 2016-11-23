require 'subjects/cellect_client'
require 'subjects/postgresql_selection'
require 'subjects/complete_remover'

module Subjects
  class StrategySelection
    include Logging

    attr_reader :workflow, :user, :subject_set_id, :limit, :strategy_param

    def initialize(workflow, user, subject_set_id, limit=SubjectQueue::DEFAULT_LENGTH, strategy_param=nil)
      @workflow = workflow
      @user = user
      @subject_set_id = subject_set_id
      @limit = limit
      @strategy_param = strategy_param
    end

    def select
      used_strategy, selected_ids = select_sms_ids
      eventlog.info("Selected subjects", desired_strategy: strategy, used_strategy: used_strategy, subject_ids: selected_ids)

      selected_ids = selected_ids.compact
      incomplete_ids = Subjects::CompleteRemover.new(user, workflow, selected_ids).incomplete_ids
      eventlog.info("Selected subjects after cleanup", desired_strategy: strategy, used_strategy: used_strategy, subject_ids: incomplete_ids)
      incomplete_ids
    end

    def strategy
      @strategy ||= case
      when configured_to_use_cellect?
        :cellect
      when configured_to_use_cellect_ex?
        :cellect_ex
      when automatically_use_cellect?
        :cellect
      else
        nil
      end
    end

    private

    def select_sms_ids
      [strategy, strategy_sms_ids]
    rescue Subjects::CellectClient::ConnectionError, CellectExClient::GenericError
      [:default, default_strategy_sms_ids]
    end

    def configured_to_use_cellect?
      return nil unless Panoptes.flipper.enabled?("cellect")
      strategy_param == :cellect || workflow.subject_selection_strategy.to_s == 'cellect'
    end

    def configured_to_use_cellect_ex?
      return nil unless Panoptes.flipper.enabled?("cellect_ex")
      strategy_param == :cellect_ex || workflow.subject_selection_strategy.to_s == 'cellect_ex'
    end

    def automatically_use_cellect?
      return nil unless Panoptes.flipper.enabled?("cellect")
      workflow.using_cellect?
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

    def run_cellection
      cellect_params = [ workflow.id, user.try(:id), subject_set_id, limit ]
      subject_ids = yield cellect_params
      sms_scope = SetMemberSubject.by_subject_workflow(subject_ids, workflow.id)
      sms_scope.pluck("set_member_subjects.id")
    end
  end
end
