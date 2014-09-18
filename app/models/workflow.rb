class Workflow < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include SubjectCounts
  include Translatable

  attr_accessible :name, :tasks, :project_id, :grouped, :pairwise, :prioritized, :primary_language

  belongs_to :project
  has_and_belongs_to_many :subject_sets
  has_many :classifications

  validates_presence_of :project

  can_through_parent :project, :update, :show, :destroy
end
