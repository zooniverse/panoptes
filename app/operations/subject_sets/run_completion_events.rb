# frozen_string_literal: true

module SubjectSets
  class RunCompletionEvents < Operation
    object :subject_set
    object :workflow

    validates :subject_set, :workflow, presence: true

    def execute
      # only run these events if the subject set is opted in for completion events
      return unless subject_set.run_completion_events?

      create_workflow_classifications_export
      notify_project_team
    end

    private

    def notify_project_team
      SubjectSetCompletedMailerWorker.perform_async(subject_set.id)
    end

    def create_workflow_classifications_export
      # use a fake Api / internal user here to trigger the rate limiter
      fake_requesting_user = ApiUser.new(User.new(id: -1))
      # override the recipients list to ensure the dump mailer uses the subject_set.communication_emails list
      params = { media: { metadata: { recipients: [] } } }
      CreateClassificationsExport.with(api_user: fake_requesting_user, object: subject_set).run!(params)
    end
  end
end
