module Subjects
  class BuiltInSelector
    def initialize(workflow)
      @workflow = workflow
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

    def get_subjects(user_id, group_id, limit)
      []
    end

    def workflow_id
      @workflow.id
    end
  end
end
