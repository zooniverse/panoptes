module UserSeenSubjectUpdater
  def self.update_user_seen_subjects(params)
    begin
      UserSeenSubject.add_seen_subject_for_user(**params)
    rescue UserSeenSubject::InvalidSubjectIdError => e
      raise Api::UserSeenSubjectIdError.new(e.message)
    end
  end
end
