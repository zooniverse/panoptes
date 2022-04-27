module Subjects
  class Selector

    class MissingParameter < StandardError; end
    class MissingSubjectSet < StandardError; end
    class MissingSubjects < StandardError; end
    class MalformedSelectedIds < StandardError; end

    SELECTION_STATE_ENUM = {
      0 => :normal,
      1 => :internal_fallback,
      2 => :failover_fallback
    }.freeze

    attr_reader :user, :params

    def initialize(user, params)
      @user, @params = user, params
      @selection_state = 0
    end

    def get_subject_ids
      raise workflow_id_error unless !!params[:workflow_id]
      raise group_id_error if needs_set_id?
      raise missing_subject_set_error if workflow.subject_sets.empty?
      raise missing_subjects_error if workflow.set_member_subjects.empty?
      selected_subject_ids
    end

    def selected_subject_ids
      if workflow_has_data?
        subject_ids = run_strategy_selection
        @selection_state = 0
      end

      if subject_ids.blank? && workflow_has_data?
        subject_ids = internal_fallback
        @selection_state = 1
      end

      if subject_ids.blank?
        subject_ids = DatabaseReplica.read('fallback_subject_selection_from_replica') do
          fallback_limit = ENV.fetch('FALLBACK_SELECTION_LIMIT', 100)
          opts = { subject_set_id: subject_set_id }
          FallbackSelection.new(workflow, fallback_limit, opts).any_workflow_data
        end
        @selection_state = 2
      end

      # when on Rails 5
      # move to AR_Scope.order(["idx(array[?]), id", subject_ids])
      # instead of manually checking and raising
      unless subject_ids.all? { |i| i.is_a? Integer }
        raise MalformedSelectedIds.new(
          "Selector returns non-integers, hacking attempt?!"
        )
      end

      subject_ids
    end

    def workflow
      @workflow ||= Workflow.find_without_json_attrs(params[:workflow_id])
    end

    def workflow_has_data?
      @workflow_has_data ||= !workflow.finished_at
    end

    def selection_state
      SELECTION_STATE_ENUM[@selection_state]
    end

    private

    def run_strategy_selection
      Subjects::StrategySelection.new(
        workflow,
        user,
        subject_set_id,
        subjects_page_size
      ).select
    end

    def fallback_selector
      @fallback_selector ||= PostgresqlSelection.new(
        workflow,
        user,
        { limit: subjects_page_size, subject_set_id: subject_set_id }
      )
    end

    def internal_fallback
      subject_ids = DatabaseReplica.read('fallback_subject_selection_from_replica') do
        fallback_selector.select
      end

      data_available = !subject_ids.empty?
      if data_available && Panoptes.flipper[:selector_sync_error_reload].enabled?
        NotifySubjectSelectorOfChangeWorker.perform_async(workflow.id)
      end

      subject_ids
    end

    def needs_set_id?
      workflow.grouped && !params.has_key?(:subject_set_id)
    end

    def workflow_id_error
      raise MissingParameter.new("workflow_id parameter missing")
    end

    def group_id_error
      MissingParameter.new("subject_set_id parameter missing for grouped workflow")
    end

    def missing_subject_set_error
      MissingSubjectSet.new("no subject set is associated with this workflow")
    end

    def missing_subjects_error
      MissingSubjects.new("No data available for selection")
    end

    def subjects_page_size(default_page_size=10)
      page_size = (params[:page_size] || workflow.selector_page_size(default_page_size)).to_i

      # update the params as they flow through the system, i.e. to the serializer
      params[:page_size] ||= page_size

      page_size
    end

    def subject_set_id
      params[:subject_set_id]
    end
  end
end
