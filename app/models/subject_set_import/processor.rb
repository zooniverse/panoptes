# frozen_string_literal: true

class SubjectSetImport::Processor
  class FailedImport < StandardError; end
  attr_reader :subject_set, :uploader

  # TODO: we don't need this subject set context anymore
  def initialize(subject_set, uploader)
    @subject_set = subject_set
    @uploader = uploader
  end

  # TODO modify spec and cleanup beahviours
  # perhaps this class can go / change to be a subejct builder??
  def import(external_id, attributes)
    subject = Subject.new
    subject.external_id = external_id
    subject.project_id = subject_set.project_id
    subject.upload_user_id = uploader.id
    subject.assign_attributes(attributes.except(:locations))

    Subject.location_attributes_from_params(attributes[:locations]).each do |location_attributes|
      subject.locations.build(location_attributes)
    end

    subject
  end
end
