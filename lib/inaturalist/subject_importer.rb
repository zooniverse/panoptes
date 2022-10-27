# frozen_string_literal: true

module Inaturalist
  class SubjectImporter
    attr_reader :subject_set_import

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
        subject.subject_sets << @subject_set

        Subject.location_attributes_from_params(obs.locations).each do |location_attributes|
          subject.locations.build(location_attributes)
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
      @subject_set_import ||= SubjectSetImport.new(user_id: @uploader.id, subject_set_id: @subject_set.id)
    end
  end
end
