module Subjects
  class CellectSelector
    attr_reader :workflow

    def initialize(workflow)
      @workflow = workflow
    end

    def id
      :cellect
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

      smses = workflow.set_member_subjects.where(subject_id: subject_id)
      smses.each do |sms|
        self.class.client.remove_subject(subject_id, workflow.id, sms.subject_set_id)
      end
    end

    def get_subjects(user, group_id, limit)
      return unless enabled?

      subject_ids = self.class.client.get_subjects(workflow.id, user.try(&:id), group_id, limit)
      sms_scope = SetMemberSubject.by_subject_workflow(subject_ids, workflow.id)
      sms_scope.pluck("set_member_subjects.id")
    end

    def enabled?
      Panoptes.flipper["cellect"].enabled?
    end

    def self.client
      @client ||= CellectClient
    end
  end
end
