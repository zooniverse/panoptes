class Classification < ActiveRecord::Base
  belongs_to :grouped_subject
  belongs_to :project
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :grouped_subject, :user, :project, :workflow, :annotations
end
