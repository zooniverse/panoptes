module Subjects
  class SelectorContext
    attr_reader :api_user, :workflow, :subject_ids

    def initialize(api_user, workflow, subject_ids)
      @api_user = api_user
      @workflow = workflow
      @subject_ids = subject_ids
    end

    def format
      if Panoptes.flipper[:skip_subject_selection_context].enabled?
        return {}
      end

      {
        user_seen: user_seen,
        url_format: :get,
        favorite_subject_ids: favorite_subject_ids,
        retired_subject_ids: retired_subject_ids,
        user_has_finished_workflow: user_has_finished_workflow?,
        select_context: true
      }.compact
    end

    private

    def favorite_subject_ids
      FavoritesFinder.find(api_user.user, workflow.project_id, subject_ids)
    end

    def retired_subject_ids
      SubjectWorkflowRetirements.find(workflow.id, subject_ids)
    end

    def user_seen
      if user_id = api_user.id
        UserSeenSubject.where(
          user_id: user_id,
          workflow_id: workflow.id
        ).first
      end
    end

    def user_has_finished_workflow?
      api_user.user&.has_finished?(workflow)
    end
  end
end
