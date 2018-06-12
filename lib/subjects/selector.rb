module Subjects
  class Selector
    include Logging

    class MissingParameter < StandardError; end
    class MissingSubjectSet < StandardError; end
    class MissingSubjects < StandardError; end

    attr_reader :user, :params, :workflow, :scope

    def initialize(user, workflow, params, scope=Subject.all)
      @user, @workflow, @params, @scope = user, workflow, params, scope
    end

    def get_subjects
      raise workflow_id_error unless workflow
      raise group_id_error if needs_set_id?
      raise missing_subject_set_error if workflow.subject_sets.empty?
      raise missing_subjects_error if workflow.set_member_subjects.empty?
      selected_subjects
    end

    def selected_subjects
      unless workflow.finished_at
        subject_ids = run_strategy_selection
      end

      if subject_ids.blank?
        subject_ids = fallback_selection
      end

      active_subjects_in_selection_order(subject_ids)
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

    def fallback_selection
      opts = { limit: subjects_page_size, subject_set_id: subject_set_id }
      fallback_selector = PostgresqlSelection.new(workflow, user, opts)

      subject_ids = fallback_selector.select
      if data_available = !subject_ids.empty?
        if Panoptes.flipper[:selector_sync_error_reload].enabled?
          NotifySubjectSelectorOfChangeWorker.perform_async(workflow.id)
        end
      end

      if subject_ids.blank?
        fallback_selector.any_workflow_data
      else
        subject_ids
      end
    end

    def active_subjects_in_selection_order(subject_ids)
      scope
      .active
      .where(id: subject_ids)
      .order("idx(array[#{subject_ids.join(',')}], id)")
    end


    def needs_set_id?
      workflow.grouped && !params.has_key?(:subject_set_id)
    end

    def workflow_id_error
      MissingParameter.new("workflow_id parameter missing")
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

    def subjects_page_size
      page_size = params[:page_size] ? params[:page_size].to_i : 10
      params.merge!(page_size: page_size)
      page_size
    end

    def subject_set_id
      params[:subject_set_id]
    end
  end
end
