module Subjects
  class Selector
    class MissingParameter < StandardError; end
    class MissingSubjectSet < StandardError; end
    class MissingSubjects < StandardError; end

    attr_reader :user, :params, :workflow

    def initialize(user, workflow, params, scope)
      @user, @workflow, @params, @scope = user, workflow, params, scope
    end

    def get_subjects
      raise workflow_id_error unless workflow
      raise group_id_error if needs_set_id?
      raise missing_subject_set_error if workflow.subject_sets.empty?
      raise missing_subjects_error if workflow.set_member_subjects.empty?
      [ selected_subjects, context.merge(selected: true, url_format: :get) ]
    end

    def selected_subjects
      sms_ids = run_strategy_selection
      sms_ids = fallback_selection if sms_ids.blank?
      active_subjects_in_selection_order(sms_ids)
    end

    private

    def active_subjects_in_selection_order(sms_ids)
      @scope.active
      .eager_load(:set_member_subjects)
      .where(set_member_subjects: {id: sms_ids})
      .order("idx(array[#{sms_ids.join(',')}], set_member_subjects.id)")
    end

    def fallback_selection
      opts = { limit: subjects_page_size, subject_set_id: subject_set_id }
      fallback_selector = PostgresqlSelection.new(workflow, user, opts)

      sms_ids = []
      sms_ids = fallback_selector.select if workflow.using_cellect?

      if sms_ids.blank?
        fallback_selector.any_workflow_data
      else
        sms_ids
      end
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

    def context
      @context ||= {
        workflow: workflow,
        user_seen: UserSeenSubject.where(user: user, workflow: workflow),
        finished_workflow: user&.has_finished?(workflow)
      }
    end

    def subject_set_id
      params[:subject_set_id]
    end

    def run_strategy_selection
      Subjects::StrategySelection.new(
        workflow,
        user,
        subject_set_id,
        subjects_page_size
      ).select
    end
  end
end
