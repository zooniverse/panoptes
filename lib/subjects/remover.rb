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
        ActiveRecord::Base.transaction do
          orphan.delete
          locations.map(&:destroy)
          set_member_subjects.map(&:destroy)
        end
      else
        raise_non_orphan_error
      end
    end

    private

    def can_be_removed?
      !!orphan
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
  end
end
