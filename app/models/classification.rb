class Classification < ActiveRecord::Base
  belongs_to :set_member_subject
  belongs_to :project
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :set_member_subject, :user, :project, :workflow, :annotations
end
