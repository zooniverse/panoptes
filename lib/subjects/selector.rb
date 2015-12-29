module Subjects
  class Selector
    class MissingParameter < StandardError; end
    class MissingSubjectQueue < StandardError; end
    class MissingSubjectSet < StandardError; end

    attr_reader :user, :params, :workflow

    def initialize(user, workflow, params, scope)
      @user, @workflow, @params, @scope = user, workflow, params, scope
    end

    def queued_subjects
      raise workflow_id_error unless workflow
      raise group_id_error if needs_set_id?
      raise missing_subject_set_error if workflow.subject_sets.empty?
      unless queue = user_subject_queue
        raise MissingSubjectQueue.new("No queue defined for user. Building one now, please try again.")
      end
      subjects = selected_subjects(sms_ids_from_queue(queue))
      [ subjects, queue_context.merge(selected: true, url_format: :get) ]
    end

    def selected_subjects(sms_ids)
      @scope.eager_load(:set_member_subjects)
        .where(set_member_subjects: {id: sms_ids})
        .order("idx(array[#{sms_ids.join(',')}], set_member_subjects.id)")
    end

    private

    def sms_ids_from_queue(queue)
      sms_ids = queue.next_subjects(subjects_page_size)
      if sms_ids.blank?
        fallback_selection
      else
        dequeue_for_logged_in_user(sms_ids)
        sms_ids
      end
    end

    def fallback_selection
      select_limit = 5
      sms_ids = PostgresqlSelection.new(workflow, user.user)
        .select(limit: select_limit, subject_set_id: subject_set_id)
      if sms_ids.blank?
        non_logged_in_queue = find_subject_queue(nil)
        sms_ids = non_logged_in_queue.next_subjects(select_limit)
      end
      sms_ids
    end

    def needs_set_id?
      workflow.grouped && !params.has_key?(:subject_set_id)
    end

    def workflow_id_error
      MissingParameter.new("workflow_id parameter missing")
    end

    def group_id_error
      MissingParameter.new("subject_set_id parameter missing for grouped workflow")
    end

    def missing_subject_set_error
      MissingSubjectSet.new("no subject set is associated with this workflow")
    end

    def subjects_page_size
      page_size = params[:page_size] ? params[:page_size].to_i : 10
      params.merge!(page_size: page_size)
      page_size
    end

    def finished_workflow?
      @finished_workflow ||= workflow.finished? || user.has_finished?(workflow)
    end

    def queue_user
      @queue_user ||= finished_workflow? ? nil : user.user
    end

    def queue_context
      @queue_context ||=
      if finished_workflow?
        {workflow: workflow, user_seen: UserSeenSubject.where(user: user.user, workflow: workflow)}
      else
        {}
      end
    end

    def subject_set_id
      params[:subject_set_id]
    end

    def user_subject_queue
      if queue = find_subject_queue
        queue
      else
        SubjectQueue.create_for_user(workflow, queue_user, set_id: subject_set_id)
      end
    end

    def find_subject_queue(user=queue_user)
      SubjectQueue.by_set(subject_set_id)
        .find_by(user: user, workflow: workflow)
    end

    def dequeue_for_logged_in_user(sms_ids)
      if queue_user
        DequeueSubjectQueueWorker.perform_async(workflow.id, sms_ids, queue_user.try(:id), subject_set_id)
      end
    end
  end
end
