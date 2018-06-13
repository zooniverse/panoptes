module Subjects
  class CompleteRemover

    attr_reader :user, :workflow, :subject_ids

    def initialize(user, workflow, subject_ids)
      @user = user
      @workflow = workflow
      @subject_ids = subject_ids
    end

    def incomplete_ids
      if subject_ids.empty?
        subject_ids
      else
        subject_ids - retired_seen_subject_ids
      end
    end

    private

    def retired_seen_subject_ids
      retired_subject_ids | user_seen_subject_ids
    end

    def retired_subject_ids
      SubjectWorkflowStatus
      .where(workflow_id: workflow.id)
      .where.not(retired_at: nil)
      .where(subject_id: subject_ids)
      .pluck(:subject_id)
    end

    def user_seen_subject_ids
      user_seen_subject = UserSeenSubject.find_by(
        user: user,
        workflow: workflow
      )

      if user_seen_subject
        user_seen_subject.subject_ids
      else
        []
      end
    end
  end
end
