class Workflow < ActiveRecord::Base
  include Linkable
  include Translatable
  include RoleControl::ParentalControlled
  include SubjectCounts

  has_paper_trail only: [:tasks, :grouped, :pairwise, :prioritized]

  belongs_to :project
  has_many :subject_sets
  has_many :classifications
  has_many :user_seen_subjects
  has_one :expert_subject_set, -> { expert_sets }, class_name: "SubjectSet"
  belongs_to :tutorial_subject, class_name: "Subject"

  validates_presence_of :project

  can_through_parent :project, :update, :index, :show, :destroy, :update_links,
                     :destroy_links, :translate, :versions, :version
  
  can_be_linked :subject_set, :same_project?, :model
  can_be_linked :subject_queue, :scope_for, :update, :user
  can_be_linked :aggregation, :scope_for, :update, :user

  def self.same_project?(subject_set)
    where(project: subject_set.project)
  end
  
  def tasks
    read_attribute(:tasks).with_indifferent_access
  end
end
