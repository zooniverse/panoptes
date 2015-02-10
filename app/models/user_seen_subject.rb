class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  def self.add_seen_subjects_for_user(user: nil, workflow: nil, subject_ids: nil)
    uss = self.find_or_create_by!(user: user, workflow: workflow)
    uss.add_subjects(subject_ids)
  end

  def add_subjects(subjects)
    subject_ids_will_change!
    subject_ids.concat(subjects)
    save!
  end
end
