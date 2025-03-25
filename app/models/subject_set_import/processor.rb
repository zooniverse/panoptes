# frozen_string_literal: true

class SubjectSetImport::Processor
  class FailedImport < StandardError; end
  attr_reader :subject_set, :uploader

  def initialize(subject_set, uploader)
    @subject_set = subject_set
    @uploader = uploader
  end

  def import(external_id, attributes)
    subject = find_or_initialize_subject(external_id)

    Subject.transaction do
      subject.subject_sets << subject_set
      subject.project_id = subject_set.project_id
      subject.uploader = uploader
      subject.assign_attributes(attributes.except(:locations))

      Subject.location_attributes_from_params(attributes[:locations]).each do |location_attributes|
        subject.locations.build(location_attributes)
      end

      subject.save!
    end
  rescue ActiveRecord::RecordInvalid => e
    raise FailedImport, e.message
  end

  private

  def find_or_initialize_subject(external_id)
    # Note: this query doesn't have an index but should be
    # constrained by the SubjectSet mapping via SetMemberSubjects
    subject_set.subjects.where(external_id: external_id).first_or_initialize
  end
end
