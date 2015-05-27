class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  def self.add_seen_subjects_for_user(user: nil, workflow: nil, subject_ids: nil)
    uss = where(user: user, workflow: workflow)
    if uss.exists?
      uss.add_subjects(subject_ids)
    else
      uss.create!(subject_ids: subject_ids)
    end
  end

  def self.add_subjects(subjects)
    update_all(["subject_ids = uniq(subject_ids + array[?])", subjects])
  end

  def subjects_seen?(ids)
    Array.wrap(ids).any? { |id| subject_ids.include?(id) }
  end
end
