class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow
  validates_presence_of :user, :workflow

  class InvalidSubjectIdError < StandardError; end

  def add_subject(subject)
    unless subject.persisted?
      raise InvalidSubjectIdError.new("Ensure the subject is persisted with an id.")
    end
    subject_ids << subject.id
    save!
  end
end
