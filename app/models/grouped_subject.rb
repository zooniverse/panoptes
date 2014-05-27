class GroupedSubject < ActiveRecord::Base
  belongs_to :subject_group
  belongs_to :subject

  enum state: [:active, :inactive, :retired]

  validates_presence_of :subject_group, :subject
end
