# frozen_string_literal: true

module Inaturalist
  class SubjectImporter
    class FailedImport < StandardError; end

    def initialize(user_id, subject_set_id)
      @uploader = User.find(user_id)
      @subject_set = SubjectSet.find(subject_set_id)
    end

    def to_subject(obs)
      subject = find_or_initialize_subject(obs.external_id)
      subject.project_id = @subject_set.project_id
      subject.uploader = @uploader
      subject.metadata = obs.metadata

      Subject.location_attributes_from_params(obs.locations).each do |location_attributes|
        # Don't insert a new location if an existing location shares the same src & content_type
        subject.locations.build(location_attributes) unless location_exists?(location_attributes, subject.locations)
      end
      subject
    end

    def import_subjects(subjects_to_import)
      Subject.import subjects_to_import, on_duplicate_key_update: [:metadata, :updated_at]
    end

    def import_smses(smses_to_import)
      SetMemberSubject.import smses_to_import, on_duplicate_key_ignore: true
    end

    def build_smses(subject_import_results)
      subject_import_results.ids.map do |subject_id|
        sms = SetMemberSubject.find_or_initialize_by(subject_set_id: @subject_set.id, subject_id: subject_id)
        sms.random = rand unless sms.random?
        sms
      end
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
