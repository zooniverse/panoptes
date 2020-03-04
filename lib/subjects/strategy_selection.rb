module Subjects
  class StrategySelection
    include Logging

    DEFAULT_LIMIT = 20

    attr_reader :workflow, :user, :subject_set_id, :limit

    def initialize(workflow, user, subject_set_id, limit=DEFAULT_LIMIT)
      @workflow = workflow
      @user = user
      @subject_set_id = subject_set_id
      @limit = limit
    end

    def select
      selected_ids = select_subject_ids.compact

      if Panoptes.flipper[:remove_complete_subjects].enabled?
        Subjects::CompleteRemover.new(
          user,
          workflow,
          selected_ids
        ).incomplete_ids
      else
        selected_ids
      end
    end

    private

    def select_subject_ids
      select_with(desired_selector)
    rescue CellectClient::ConnectionError, DesignatorClient::GenericError
      []
    end

    def select_with(selector)
      selector.get_subjects(user, subject_set_id, limit)
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
