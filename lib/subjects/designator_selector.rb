module Subjects
  class DesignatorSelector
    attr_reader :workflow

    def initialize(workflow)
      @workflow = workflow
    end

    def id
      :designator
    end

    def add_seen(user_id, subject_id)
      return unless enabled?
      self.class.client.add_seen(workflow.id, user_id, subject_id)
    end

    def load_user(user_id)
      return unless enabled?
      self.class.client.load_user(workflow.id, user_id)
    end

    def reload_workflow
      return unless enabled?
      self.class.client.reload_workflow(workflow.id)
    end

    def remove_subject(subject_id)
      return unless enabled?
      self.class.client.remove_subject(subject_id, workflow.id)
    end

    def get_subjects(user, group_id, limit)
      return [] unless enabled?

      self.class.client.get_subjects(workflow.id, user.try(&:id), group_id, limit)
    end

    def enabled?
      Panoptes.flipper["designator"].enabled?
    end

    def self.client
      @client ||= DesignatorClient.new
    end
  end
end
