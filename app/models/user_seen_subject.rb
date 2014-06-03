class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow
  validates_presence_of :user, :workflow

  def add_subject(subject) 
    subject_ids << subject.id
    subject_ids_will_change!
    save!
  end
end
