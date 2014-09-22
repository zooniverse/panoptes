class UserEnqueuedSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow
  attr_accessible :user, :workflow

  def self.enqueue_subject_for_user(user: nil, workflow: nil, subject_id: nil)
    ues = find_or_create_by!(user: user, workflow: workflow)
    ues.add_subject_id(subject_id)
  end

  def self.dequeue_subject_for_user(user: nil, workflow: nil, subject_id: nil)
    ues = find_by!(user: user, workflow: workflow)
    ues.remove_subject_id(subject_id)
  end
  
  def sample_subjects(limit=10)
    subject_ids.sample(limit)
  end

  def add_subject_id(id)
    subject_ids_will_change!
    subject_ids << id
    save!
  end

  def remove_subject_id(id)
    subject_ids_will_change!
    subject_ids.delete(id)
    save!
  end
end
