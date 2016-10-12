require 'csv'

class SubjectImportWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(project_id, user_id, subject_set_id, csv_url)
    project = Project.find(project_id)
    user = User.find(user_id)
    subject_set = project.subject_sets.find(subject_set_id)
    raise unless project && user && subject_set

    rows = CSV.parse(download_csv(csv_url), headers: true).map do |row|
      header, external_src = row.delete("url")
      ext = external_src.split(".").last
      metadata = row.to_hash
      content_type = case ext
      when /jpe?g/i
        "image/jpeg"
      when /png/i
        "image/png"
      else
        nil
      end

      if external_src.nil? || content_type.nil? || metadata.empty?
        raise "No src / content type from file"
      end

      {external_src: external_src, metadata: metadata, content_type: content_type}
    end

    rows.in_groups_of(500, false) do |subject_group|
      subjects = []
      failed_subjects = []

      urls = subject_group.map {|i| i[:external_src] }

      existing_subjects = Subject.joins(:locations).where(project_id: project.id, upload_user_id: user.id,
                                                          media: {external_link: true, src: urls}).load

      subject_group.each do |item|
        subject = existing_subjects.find {|i| i.locations.map(&:src).include?(item[:external_src])}

        if subject
          subjects << subject
        else
          subject = Subject.new(project_id: project.id, upload_user_id: user.id, metadata: item[:metadata])
          location_params = { content_type: item[:content_type], external_link: true, src: item[:external_src], metadata: { index: 0 }}
          subject.locations.build(location_params)

          if subject.save
            subjects << subject
          else
            failed_subjects << subject
          end
        end
      end

      unless failed_subjects.empty?
        raise "failed to create some fo the subjects..."
      end

      #now link to the subject sets
      linked_subject_ids = SetMemberSubject.where(subject_set_id: subject_set.id, subject_id: subjects.map(&:id)).pluck(:subject_id)
      subject_ids_to_link = subjects.map(&:id).reject {|i| linked_subject_ids.include?(i) }

      if Subject.where(id: subject_ids_to_link).count != subject_ids_to_link.size
        raise "Error: check the subject set and all the subjects exist."
      end

      new_sms_values = subject_ids_to_link.map do |subject_id|
        [ subject_set.id, subject_id, rand ]
      end

      sset_import_cols = %w(subject_set_id subject_id random)
      SetMemberSubject.import sset_import_cols, new_sms_values, validate: false
      SubjectSetSubjectCounterWorker.new.perform(subject_set.id)
    end
  end

  def download_csv(csv_url)
    response = Faraday.get(csv_url)
    raise "Invalid CSV URL" unless response.status == 200
    response.body
  end
end
