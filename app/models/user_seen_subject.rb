class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  attr_accessible :user, :workflow

  def self.add_seen_subject_for_user(user: nil, workflow: nil, set_member_subject_id: nil)
    uss = self.find_or_create_by!(user: user, workflow: workflow)
    uss.add_set_member_subject_id(set_member_subject_id)
  end

  def add_set_member_subject_id(id)
    set_member_subject_ids_will_change!
    set_member_subject_ids << id
    save!
  end
end
