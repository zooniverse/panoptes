class Workflow < ActiveRecord::Base
  include SubjectCounts

  attr_accessible :name, :tasks, :project_id, :grouped, :pairwise, :prioritized

  belongs_to :project
  has_and_belongs_to_many :subject_sets
  has_many :classifications

  validates_presence_of :project
end
