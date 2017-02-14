module Subjects
  class CellectExSelector
    def initialize(workflow)
      @workflow = workflow
    end

    def add_seen(user_id, subject_id)
      return if disabled?
      self.class.client.add_seen(workflow_id, user_id, subject_id)
    end

    def load_user(user_id)
      return if disabled?
      self.class.client.load_user(workflow_id, user_id)
    end

    def reload_workflow
      return if disabled?
      self.class.client.reload_workflow(workflow_id)
    end

    def remove_subject(subject_id, group_id)
      return if disabled?
      self.class.client.remove_subject(subject_id, workflow_id, group_id)
    end

    def get_subjects(user_id, group_id, limit)
      return if disabled?
      self.class.client.get_subjects(workflow_id, user_id, group_id, limit)
    end

    def workflow_id
      @workflow.id
    end

    def disabled?
      !Panoptes.flipper["cellect_ex"].enabled?
    end

    def self.client
      @client ||= CellectExClient.new
    end
  end
end
