module Subjects
  class SelectorContext
    attr_reader :selector, :subject_ids
    delegate :user, :workflow, to: :selector

    def initialize(selector, subject_ids)
      @selector = selector
      @subject_ids = subject_ids
    end

    def format
      if Panoptes.flipper[:skip_subject_selection_context].enabled?
        {}
      else
        {
          user_seen_subject_ids: user_seen_subject_ids,
          favorite_subject_ids: favorite_subject_ids,
          retired_subject_ids: retired_subject_ids,
          user_has_finished_workflow: user_has_finished_workflow,
          finished_workflow: finished_workflow?,
          selection_state: :normal,
          url_format: :get,
          select_context: true
        }.compact
      end
    end

    private

    def favorite_subject_ids
      FavoritesFinder.find(user, workflow.project_id, subject_ids)
    end

    def retired_subject_ids
      SubjectWorkflowRetirements.find(workflow.id, subject_ids)
    end

    def user_seen_subject_ids
      seen_subject_ids = []

      if user
        uss = UserSeenSubject.where(
          user_id: user.id,
          workflow_id: workflow.id
        ).first

        if uss
          seen_subject_ids = uss.subject_ids
        end
      end

      seen_subject_ids
    end

    def finished_workflow?
      !!workflow.finished_at
    end

    def user_has_finished_workflow
      return true if finished_workflow?

      if user
        case selector.selection_state
        when :normal # selector service returned data
          seen_and_retired_ids = (user_seen_subject_ids | retired_subject_ids)
          unseen_non_retired_selected_subject_ids = subject_ids - seen_and_retired_ids
          unseen_non_retired_selected_subject_ids.empty?
        when :internal_fallback # failed over to internal selector but returned data
          false
        when :failover_fallback # no selection service returned data, they are finished
          true
        end
      else
        # no known user and workflow has data
        false
      end
    end
  end
end
