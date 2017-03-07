require 'subjects/postgresql_selection'
require 'subjects/complete_remover'

module Subjects
  class StrategySelection
    include Logging

    attr_reader :workflow, :user, :subject_set_id, :limit

    def initialize(workflow, user, subject_set_id, limit=SubjectQueue::DEFAULT_LENGTH)
      @workflow = workflow
      @user = user
      @subject_set_id = subject_set_id
      @limit = limit
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
      when configured_to_use_designator?
        :designator
      when automatically_use_cellect?
        :cellect
      else
        nil
      end
    end

    private

    def select_sms_ids
      select_with(desired_selector)
    rescue CellectClient::ConnectionError, DesignatorClient::GenericError
      select_with(default_selector)
    end

    def configured_to_use_cellect?
      return nil unless Panoptes.flipper.enabled?("cellect")
      workflow.subject_selection_strategy.to_s == 'cellect'
    end

    def configured_to_use_designator?
      return nil unless Panoptes.flipper.enabled?("designator")
      workflow.subject_selection_strategy.to_s == 'designator'
    end

    def automatically_use_cellect?
      return nil unless Panoptes.flipper.enabled?("cellect")
      workflow.using_cellect?
    end

    def select_with(selector)
      [selector.id, selector.get_subjects(user, subject_set_id, limit)]
    end

    def desired_selector
      if workflow.subject_selector.enabled?
        workflow.subject_selector
      else
        default_selector
      end
    end

    def default_selector
      BuiltInSelector.new(workflow)
    end
  end
end
