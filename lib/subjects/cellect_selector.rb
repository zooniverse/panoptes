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

      CellectClient.add_seen(workflow.id, user_id, subject_id)
    end

    def load_user(user_id)
      return unless enabled?

      CellectClient.load_user(workflow.id, user_id)
    end

    def reload_workflow
      return unless enabled?

      CellectClient.reload_workflow(workflow.id)
    end

    def remove_subject(subject_id)
      return unless enabled?

      smses = workflow.set_member_subjects.where(subject_id: subject_id)
      smses.each do |sms|
        CellectClient.remove_subject(subject_id, workflow.id, sms.subject_set_id)
      end
    end

    def get_subjects(user, group_id, limit)
      return unless enabled?

      CellectClient.get_subjects(workflow.id, user.try(&:id), group_id, limit)
    end

    def enabled?
      Flipper.enabled?(:cellect)
    end
  end
end
