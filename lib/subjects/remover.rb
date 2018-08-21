module Subjects
  class Remover
    attr_reader :subject_id, :panoptes_client

    def initialize(subject_id, client=nil)
      @subject_id = subject_id
      @panoptes_client = client || Panoptes::Client.new(env: Rails.env)
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
      return false if has_been_collected_or_classified?

      # subject has been talked about
      return false if has_been_talked_about?

      # subject has been counted or retired via a SubjectWorkflowStatus record
      return false if has_been_counted_or_retired?

      # subject has no record of use in zooniverse
      true
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

    def has_been_collected_or_classified?
      !orphan_subject
    end

    def has_been_talked_about?
      panoptes_client.discussions(
        focus_id: subject_id,
        focus_type: 'Subject'
      ).any?
    end

    def notify_subject_selector(workflow_ids)
      workflow_ids.each do |workflow_id|
        NotifySubjectSelectorOfRetirementWorker.perform_async(orphan_subject.id, workflow_id)
      end
    end

    def orphan_subject_sws_scope
      SubjectWorkflowStatus.where(subject_id: subject_id)
    end

    def has_been_counted_or_retired?
      orphan_subject_sws_scope
      .where("classifications_count > 0 OR retired_at IS NOT NULL")
      .exists?
    end
  end
end
