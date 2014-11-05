class Workflow < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include SubjectCounts
  include Linkable
  include Translatable

  has_paper_trail only: [:tasks, :grouped, :pairwise, :prioritized]
  attr_accessible :name, :tasks, :project_id, :grouped, :pairwise, :prioritized, :primary_language

  belongs_to :project
  has_and_belongs_to_many :subject_sets
  has_one :current_version, -> (obj) { where(id: obj.versions.last.id) },
          class_name: "PaperTrail::Version", as: :item

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
