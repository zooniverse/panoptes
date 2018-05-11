class SubjectSetImport::Processor
  attr_reader :subject_set, :uploader

  def initialize(subject_set, uploader)
    @subject_set = subject_set
    @uploader = uploader
  end

  def import(uuid, attributes)
    subject = subject_set.subjects.where(external_id: uuid).first_or_initialize
    subject.subject_sets << subject_set
    subject.project = subject_set.project
    subject.uploader = uploader
    subject.assign_attributes(attributes.except(:locations))

    location_params(attributes[:locations]).each do |location|
      subject.locations.build(location)
    end

    subject.save!
  end

  def location_params(locations)
    (locations || []).map.with_index do |loc, i|
      location_params = case loc
                        when String
                          { content_type: Subject.nonstandard_mimetypes[loc] || loc }
                        when Hash
                          {
                            content_type: loc.keys.first,
                            external_link: true,
                            src: loc.values.first
                          }
                        end
      location_params[:metadata] = { index: i }
      location_params
    end
  end
end
