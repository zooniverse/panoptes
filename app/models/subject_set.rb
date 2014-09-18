class SubjectSet < ActiveRecord::Base
  include RoleControl::ParentalControlled
  
  attr_accessible :name, :project_id
  
  belongs_to :project
  has_many :set_member_subjects
  has_many :subjects, through: :set_member_subjects
  has_and_belongs_to_many :workflows

  validates_presence_of :project

  can_through_parent :project, :update, :show, :destroy
end
