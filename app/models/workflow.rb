class Workflow < ActiveRecord::Base
  belongs_to :project
  has_and_belongs_to_many :subject_groups

  validates_presence_of :project
end
