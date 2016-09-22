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
      sms_ids = filter_non_retired(sms_ids) unless sms_ids.blank?
      if sms_ids.blank?
        sms_ids = fallback_selection
      end
      active_subjects_in_selection_order(sms_ids)
    end

    private

    def active_subjects_in_selection_order(sms_ids)
      @scope.active
      .eager_load(:set_member_subjects)
      .where(set_member_subjects: {id: sms_ids})
      .order("idx(array[#{sms_ids.join(',')}], set_member_subjects.id)")
    end

    def filter_non_retired(sms_ids)
      retired_ids = SetMemberSubject
        .joins("INNER JOIN subject_workflow_counts ON subject_workflow_counts.subject_id = set_member_subjects.subject_id")
        .where("subject_workflow_counts.retired_at IS NOT NULL")
        .where("subject_workflow_counts.workflow_id = ?", workflow.id)
        .where(set_member_subjects: {id: sms_ids})
        .pluck(:id)
      return sms_ids if retired_ids.blank?
      retired_ids = Set.new(retired_ids)
      sms_ids.reject {|id| retired_ids.include?(id) }
    end

    def fallback_selection
      opts = { limit: subjects_page_size, subject_set_id: subject_set_id }
      selector = PostgresqlSelection.new(workflow, user, opts)
      selector.any_workflow_data
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
