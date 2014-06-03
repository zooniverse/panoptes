class Workflow < ActiveRecord::Base
  belongs_to :project
  has_and_belongs_to_many :subject_sets
  has_many :classifications

  validates_presence_of :project
end
