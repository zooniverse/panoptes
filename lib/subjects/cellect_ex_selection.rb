module Subjects
  module CellectExSelection
    def self.add_seen(workflow_id, user_id, subject_id)
      client.add_seen(workflow_id, user_id, subject_id)
    end

    def self.load_user(workflow_id, user_id)
      client.load_user(workflow_id, user_id)
    end

    def self.reload_workflow(workflow_id)
      client.reload_workflow(workflow_id)
    end

    def self.remove_subject(subject_id, workflow_id, group_id)
      client.remove_subject(subject_id, workflow_id, group_id)
    end

    def self.get_subjects(workflow_id, user_id, group_id, limit)
      client.get_subjects(workflow_id, user_id, group_id, limit)
    end

    def self.client
      @client ||= CellectExClient.new
    end
  end
end
