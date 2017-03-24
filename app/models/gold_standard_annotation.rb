class GoldStandardAnnotation < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :subject
  belongs_to :project
  belongs_to :user
  belongs_to :classification

  validates_presence_of :workflow,
    :subject,
    :project,
    :user,
    :classification,
    :metadata,
    :annotations
end
