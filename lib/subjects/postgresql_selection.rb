module Subjects
  class PostgresqlSelection
    attr_reader :workflow, :user, :opts

    def initialize(workflow, user=nil, options={})
      @workflow, @user, @opts = workflow, user, options
    end

    def select
      selection_strategy.new(available, limit).select
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
      # use a rewhere in case we've applied this clause before
      query.rewhere(subject_set_id: subject_set_ids)
    end

    def limit
      opts.fetch(:limit, 20).to_i
    end

    def subject_set_ids
      # respect the user if they want to select from a training set
      return Array.wrap(opts[:subject_set_id]) if workflow.grouped

      # default mode: do not select from training sets
      workflow.non_training_subject_sets.pluck(:id)
    end
  end
end
