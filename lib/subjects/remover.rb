module Subjects
  class Remover
    attr_reader :subject_id

    def initialize(subject_id)
      @subject_id = subject_id
    end

    def cleanup
      if can_be_removed?
        locations = orphan_subject.locations
        set_member_subjects = orphan_subject.set_member_subjects
        workflow_ids = orphan_subject.workflows.pluck(:id)
        ActiveRecord::Base.transaction do
          # clean up the linked sws records, https://github.com/zooniverse/Panoptes/pull/2822
          orphan_subject_sws_scope.delete_all
          orphan_subject.delete
          locations.map(&:destroy)
          set_member_subjects.map(&:destroy)
        end
        notify_subject_selector(workflow_ids)
        true
      else
        false
      end
    end

    private

    def can_be_removed?
      # subject has been collected or classified
      return false unless orphan_subject_scope.exists?

      # subject has been talked about
      return false unless no_talk_discussions?

      # subject has been counted or retired via a SubjectWorkflowStatus record
      if has_not_been_counted_or_retired?
        true
      else
        false
      end
    end

    def orphan_subject_scope
      Subject
      .where(id: subject_id)
      .joins("LEFT OUTER JOIN classification_subjects ON classification_subjects.subject_id = subjects.id")
      .where("classification_subjects.subject_id IS NULL")
      .joins("LEFT OUTER JOIN collections_subjects ON collections_subjects.subject_id = subjects.id")
      .where("collections_subjects.subject_id IS NULL")
    end

    def orphan_subject
      @orphan_subject ||= orphan_subject_scope.first
    end

    def no_talk_discussions?
      panoptes_client.discussions(focus_id: subject_id, focus_type: 'Subject').empty?
    end

    def panoptes_client
      @client ||= Panoptes::Client.new(env: Rails.env)
    end

    def notify_subject_selector(workflow_ids)
      workflow_ids.each do |workflow_id|
        NotifySubjectSelectorOfRetirementWorker.perform_async(orphan_subject.id, workflow_id)
      end
    end

    def orphan_subject_sws_scope
      SubjectWorkflowStatus.where(subject_id: subject_id)
    end

    def orphan_subject_sws_counted_or_retired_scope
      orphan_subject_sws_scope.where("classifications_count > 0 OR retired_at IS NOT NULL")
    end

    def has_not_been_counted_or_retired?
      !orphan_subject_sws_counted_or_retired_scope.exists?
    end
  end
end
