module Subjects
  class PostgresqlSelection
    attr_reader :workflow, :user, :opts

    def initialize(workflow, user=nil, options={})
      @workflow, @user, @opts = workflow, user, options
    end

    def select(limit_override=nil)
      @limit_override = limit_override
      results = case selection_strategy
      when :in_order
        select_results_in_order
      else
        select_results_randomly
      end
      results.take(limit)
    end

    def any_workflow_data(limit_override=nil)
      @limit_override = limit_override
      any_workflow_data_scope
      .order(random: [:asc, :desc].sample)
      .limit(limit)
      .pluck("set_member_subjects.id")
      .shuffle
    end

    private

    def available
      return @available if @available
      query = SetMemberSubject.available(workflow, user)
      if workflow.grouped
        query = query.where(subject_set_id: opts[:subject_set_id])
      end
      @available = query
    end

    def limit
      if @limit_override
        @limit_override
      else
        @limit ||= opts.fetch(:limit, 20).to_i
      end
    end

    def selection_strategy
      if workflow.prioritized
        :in_order
      else
        :other
      end
    end

    def select_results_randomly
      PostgresqlRandomSelection.new(available, limit).select
    end

    def select_results_in_order
      PostgresqlInOrderSelection.new(available, limit).select
    end

    def any_workflow_data_scope
      scope = workflow.set_member_subjects
      if workflow.grouped
        if subject_set_id = opts[:subject_set_id]
          scope = scope.where(subject_set_id: subject_set_id)
        else
          msg = "subject_set_id parameter missing for grouped workflow"
          raise Subjects::Selector::MissingParameter.new(msg)
        end
      end
      scope
    end
  end
end
