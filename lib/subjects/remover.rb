module Subjects
  class Remover
    class NonOrphan < StandardError; end

    attr_reader :subject_id

    def initialize(subject_id)
      @subject_id = subject_id
    end

    def cleanup
      if can_be_removed?
        locations = orphan.locations
        set_member_subjects = orphan.set_member_subjects
        workflow_ids = orphan.workflows.map(&:id)
        ActiveRecord::Base.transaction do
          orphan.delete
          locations.map(&:destroy)
          set_member_subjects.map(&:destroy)
        end
        notify_cellect(workflow_ids)
      else
        raise_non_orphan_error
      end
    end

    private

    def can_be_removed?
      !!orphan && no_talk_discussions?
    end

    def orphan
     @orphan ||=
       Subject
       .where(id: subject_id)
       .joins("LEFT OUTER JOIN classification_subjects ON classification_subjects.subject_id = subjects.id")
       .where("subjects.id IS NOT NULL AND classification_subjects.subject_id IS NULL")
       .joins("LEFT OUTER JOIN collections_subjects ON collections_subjects.subject_id = subjects.id")
       .where("subjects.id IS NOT NULL AND collections_subjects.subject_id IS NULL")
       .first
    end

    def raise_non_orphan_error
      raise NonOrphan, "Subject with id: #{subject_id} has linked data and cannot be removed."
    end

    def no_talk_discussions?
      talk_client.discussions(focus_id: subject_id, focus_type: 'Subject').empty?
    end

    def talk_client
      @client ||= Panoptes::TalkClient.new(url: ENV["TALK_URL"])
    end

    def notify_cellect(workflow_ids)
      workflow_ids.each do |workflow_id|
        RetireCellectWorker.perform_async(orphan.id, workflow_id)
      end
    end
  end
end
