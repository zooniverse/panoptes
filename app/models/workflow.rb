class Workflow < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include SubjectCounts
  include Translatable
  include Linkable

  attr_accessible :name, :tasks, :project_id, :grouped, :pairwise, :prioritized, :primary_language

  belongs_to :project
  has_and_belongs_to_many :subject_sets
  has_many :classifications

  validates_presence_of :project

  can_through_parent :project, :update, :show, :destroy
  
  can_be_linked :subject_set, :same_project?, :model

  def self.same_project?(subject_set)
    where(project: subject_set.project)
  end
end
