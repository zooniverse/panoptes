module Subjects
  class FallbackSelection
    attr_reader :workflow, :limit, :options

    def initialize(workflow, limit, options = {})
      @workflow, @limit, @options = workflow, limit, options
    end

    def any_workflow_data
      any_workflow_data_scope \
        .order(random: [:asc, :desc].sample)
        .limit(limit)
        .pluck("set_member_subjects.id")
        .shuffle
    end

    private

    def any_workflow_data_scope
      scope = workflow.set_member_subjects
      if workflow.grouped
        if subject_set_id = options[:subject_set_id]
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
