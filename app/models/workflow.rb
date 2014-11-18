class Workflow < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include SubjectCounts
  include Linkable
  include Translatable

  has_paper_trail only: [:tasks, :grouped, :pairwise, :prioritized]

  belongs_to :project
  has_and_belongs_to_many :subject_sets
  has_many :classifications

  validates_presence_of :project

  can_through_parent :project, :update, :show, :destroy
  
  can_be_linked :subject_set, :same_project?, :model
  can_be_linked :user_subject_queue, :scope_for, :update, :actor

  def self.same_project?(subject_set)
    where(project: subject_set.project)
  end
  
  def self.translation_scope
    @translation_scope ||= RoleControl::RoleScope.new(["translator"], false, Project)
  end
  
  def self.translatable_by(actor)
    where(project: translation_scope.build(actor))
  end

  def tasks
    read_attribute(:tasks).with_indifferent_access
  end
end
