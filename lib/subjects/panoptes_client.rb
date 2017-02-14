module Subjects
  class PanoptesClient
    def self.add_seen(workflow_id, user_id, subject_id)
      true
    end

    def self.load_user(workflow_id, user_id)
      true
    end

    def self.reload_workflow(workflow_id)
      true
    end

    def self.remove_subject(subject_id, workflow_id, group_id)
      true
    end

    def self.get_subjects(workflow_id, user_id, group_id, limit)
      []
    end
  end
end
