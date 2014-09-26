class UserSubjectQueue < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow
  attr_accessible :user, :workflow

  def self.enqueue_subject_for_user(user: nil, workflow: nil, set_member_subject_id: nil)
    ues = find_or_create_by!(user: user, workflow: workflow)
    ues.add_subject_id(set_member_subject_id)
  end

  def self.dequeue_subject_for_user(user: nil, workflow: nil, set_member_subject_id: nil)
    ues = find_by!(user: user, workflow: workflow)
    ues.remove_subject_id(set_member_subject_id)
    ues.destroy if ues.set_member_subject_ids.empty?
  end

  def self.is_subject_queued?(user: nil, workflow: nil, set_member_subject_id: nil)
    where.any(set_member_subject_ids: set_member_subject_id)
      .exists?(user: user, workflow: workflow)
  end
  
  def sample_subjects(limit=10)
    set_member_subject_ids.sample(limit)
  end

  def add_subject_id(id)
    set_member_subject_ids_will_change!
    set_member_subject_ids << id
    save!
  end

  def remove_subject_id(id)
    set_member_subject_ids_will_change!
    set_member_subject_ids.delete(id)
    save!
  end
end
