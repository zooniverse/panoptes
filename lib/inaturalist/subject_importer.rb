# frozen_string_literal: true

module Inaturalist
  class SubjectImporter
    class FailedImport < StandardError; end

    def initialize(user_id, subject_set_id)
      @uploader = User.find(user_id)
      @subject_set = SubjectSet.find(subject_set_id)
    end

    def import(obs)
      subject = find_or_initialize_subject(obs.external_id)

      Subject.transaction do
        subject.project_id = @subject_set.project_id
        subject.uploader = @uploader
        subject.metadata = obs.metadata
        # Don't add the set if it exists on an upsert, or SetMemberSubjects insert won't validate
        subject.subject_sets << @subject_set unless subject.subject_sets.include?(@subject_set)

        Subject.location_attributes_from_params(obs.locations).each do |location_attributes|
          # Don't insert a new location if an existing location shares the same src & content_type
          subject.locations.build(location_attributes) unless location_exists?(location_attributes, subject.locations)
        end
        subject.save!
      end
      subject
    rescue ActiveRecord::RecordInvalid => e
      raise FailedImport, e.message
    end

    def find_or_initialize_subject(external_id)
      # Subjects need to be upserted by external ID, which has no index.
      # So like SubjectSetImports, this scope is limited to the subject set and constrained by SetMemberSubjects
      # @combined_set_subject_scope.where(external_id: external_id).first_or_initialize
      @subject_set.subjects.where(external_id: external_id).first_or_initialize
    end

    def subject_set_import
      @subject_set_import ||= SubjectSetImport.create(user_id: @uploader.id, subject_set_id: @subject_set.id)
    end

    def location_exists?(location_attrs, locations)
      # If the incoming src, content_type, & metadata match a single location, it already exists
      locations.map do |l|
        l.src == location_attrs[:src] &&
        l.content_type == location_attrs[:content_type] &&
        l.metadata.with_indifferent_access == location_attrs[:metadata].with_indifferent_access
      end.include?(true)
    end
  end
end
