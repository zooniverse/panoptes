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
      [ selected_subjects, selected_context ]
    end

    def selected_subjects
      sms_ids = run_strategy_selection
      sms_ids = fallback_selection if sms_ids.blank?
      active_subjects_in_selection_order(sms_ids)
    end

    private

    def run_strategy_selection
      eventlog.info "Selecting subjects based on workflow config", workflow_id: workflow.id, user_id: user&.id

      Subjects::StrategySelection.new(
        workflow,
        user,
        subject_set_id,
        subjects_page_size
      ).select
    end

    def fallback_selection
      eventlog.info "Preferred strategy returned no results, trying fallback", workflow_id: workflow.id, user_id: user&.id

      opts = { limit: subjects_page_size, subject_set_id: subject_set_id }
      fallback_selector = PostgresqlSelection.new(workflow, user, opts)

      sms_ids = []
      if workflow.using_cellect?
        sms_ids = fallback_selector.select
        if data_available = !sms_ids.empty?
          if Panoptes.flipper[:cellect_sync_error_reload].enabled?
            NotifySubjectSelectorOfSubjectsChangeWorker.perform_async(workflow.id)
          end
          Honeybadger.notify(
            error_class:   "Cellect data sync error",
            error_message: "Cellect returns no data but PG selector does",
            context: {
              workflow: workflow.id
            }
          )
        end
      end

      if sms_ids.blank?
        eventlog.info "Fallback failed to return unseen unretired data, falling back to selecting anything", workflow_id: workflow.id, user_id: user&.id
        fallback_selector.any_workflow_data
      else
        sms_ids
      end
    end

    def active_subjects_in_selection_order(sms_ids)
      scope.active
        .eager_load(:set_member_subjects)
        .where(set_member_subjects: {id: sms_ids})
        .order("idx(array[#{sms_ids.join(',')}], set_member_subjects.id)")
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

    def selected_context
      {
        workflow: workflow,
        user: user,
        user_seen: user_seen,
        url_format: :get,
        select_context: selection_context_on
      }.compact
    end

    def subject_set_id
      params[:subject_set_id]
    end

    def selection_context_on
      if Panoptes.flipper[:skip_subject_selection_context].enabled?
        nil
      else
        true
      end
    end

    def user_seen
      if user
        UserSeenSubject.where(user: user, workflow: workflow).first
      end
    end
  end
end
