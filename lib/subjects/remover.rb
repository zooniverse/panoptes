module Subjects
  class Remover
    attr_reader :subject_id

    def initialize(subject_id)
      @subject_id = subject_id
    end

    def cleanup
      if can_be_removed?
        locations = orphan.locations
        set_member_subjects = orphan.set_member_subjects
        workflow_ids = orphan.workflows.pluck(:id)
        ActiveRecord::Base.transaction do
          orphan.delete
          locations.map(&:destroy)
          set_member_subjects.map(&:destroy)
        end
        notify_cellect(workflow_ids)
        true
      else
        false
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
       .where("classification_subjects.subject_id IS NULL")
       .joins("LEFT OUTER JOIN collections_subjects ON collections_subjects.subject_id = subjects.id")
       .where("collections_subjects.subject_id IS NULL")
       .first
    end

    def no_talk_discussions?
      talk_client.discussions(focus_id: subject_id, focus_type: 'Subject').empty?
    end

    def talk_client
      @client ||= Panoptes::Client.new(env: Rails.env)
    end

    def notify_cellect(workflow_ids)
      workflow_ids.each do |workflow_id|
        RetireCellectWorker.perform_async(orphan.id, workflow_id)
      end
    end
  end
end
