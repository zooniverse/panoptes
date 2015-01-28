class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  def self.add_seen_subjects_for_user(user: nil, workflow: nil, set_member_subject_ids: nil)
    uss = self.find_or_create_by!(user: user, workflow: workflow)
    uss.add_set_member_subjects(set_member_subject_ids)
  end

  def add_set_member_subjects(subjects)
    set_member_subject_ids_will_change!
    set_member_subject_ids.concat(subjects)
    save!
  end
end
