module Subjects
  class PostgresqlSelection
    attr_reader :workflow, :user, :opts

    def initialize(workflow, user=nil, options={})
      @workflow, @user, @opts = workflow, user, options
    end

    def select
      selection_strategy.new(available, limit).select
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
      query = Subjects::SetMemberSubjectSelector.new(workflow, user).set_member_subjects
      if workflow.grouped
        query = query.where(subject_set_id: opts[:subject_set_id])
      end
      query
    end

    def limit
      opts.fetch(:limit, 20).to_i
    end
  end
end
