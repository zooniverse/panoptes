module Subjects
  class BuiltInSelector
    attr_reader :workflow

    def initialize(workflow)
      @workflow = workflow
    end

    def id
      :default
    end

    def add_seen(user_id, subject_id)
      true
    end

    def load_user(user_id)
      true
    end

    def reload_workflow
      true
    end

    def remove_subject(subject_id, group_id)
      true
    end

    def get_subjects(user, subject_set_id, limit)
      Subjects::PostgresqlSelection.new(workflow, user, {limit: limit, subject_set_id: subject_set_id}).select
    end

    def enabled?
      true
    end
  end
end
