class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  attr_accessible :user, :workflow

  def self.add_seen_subject_for_user(user: nil, workflow: nil, subject_id: nil)
    uss = self.find_or_create_by!(user: user, workflow: workflow)
    uss.add_subject_id(subject_id)
  end

  def add_subject_id(subject_id)
    subject_ids_will_change!
    subject_ids << subject_id
    save!
  end
end
