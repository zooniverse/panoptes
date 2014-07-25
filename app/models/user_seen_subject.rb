class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  attr_accessible :user_id, :workflow_id

  class InvalidSubjectIdError < StandardError; end

  def self.add_seen_subject_for_user(user_id:, workflow_id:, subject_id:)
    uss = self.find_or_create_by!(user_id: user_id, workflow_id: workflow_id)
    uss.add_subject_id(subject_id)
  end

  def add_subject_id(subject_id)
    unless Subject.exists?(subject_id)
      raise InvalidSubjectIdError.new("Subject ID is invalid, possibly not persisted.")
    end
    subject_ids_will_change!
    update_attribute(:subject_ids, subject_ids << subject_id)
  end
end
