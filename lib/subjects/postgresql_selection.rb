module Subjects
  class PostgresqlSelection
    attr_reader :workflow, :user, :opts

    def initialize(workflow, user=nil, options={})
      @workflow, @user, @opts = workflow, user, options
    end

    def select
      results = selection_strategy.new(available, limit).select
      results.take(limit)
    end

    def any_workflow_data
      FallbackSelection.new(workflow, limit, opts).any_workflow_data
    end

    private

    def selection_strategy
      if workflow.prioritized
        PostgresqlInOrderSelection
      else
        PostgresqlRandomSelection
      end
    end

    def available
      return @available if @available
      query = SetMemberSubject.available(workflow, user)
      if workflow.grouped
        query = query.where(subject_set_id: opts[:subject_set_id])
      end
      @available = query
    end

    def limit
      opts.fetch(:limit, 20).to_i
    end
  end
end
