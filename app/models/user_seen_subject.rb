class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow
  validates_presence_of :user, :workflow

  def add_subject(subject) 
    subject_zooniverse_ids << subject.zooniverse_id
    subject_zooniverse_ids_will_change!
    save!
  end
end
