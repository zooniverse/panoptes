class SubjectSetImport::Processor
  attr_reader :subject_set, :uploader

  def initialize(subject_set, uploader)
    @subject_set = subject_set
    @uploader = uploader
  end

  def import(external_id, attributes)
    subject = subject_set.subjects.where(external_id: external_id).first_or_initialize
    subject.subject_sets << subject_set
    subject.project_id = subject_set.project_id
    subject.uploader = uploader
    subject.assign_attributes(attributes.except(:locations))

    Subject.location_attributes_from_params(attributes[:locations]).each do |location_attributes|
      subject.locations.build(location_attributes)
    end

    subject.save!
  end

end
