class SubjectSet < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable

  belongs_to :project
  has_many :subject_sets_workflows, dependent: :destroy
  has_many :workflows, through: :subject_sets_workflows

  has_many :set_member_subjects, dependent: :destroy
  has_many :subjects, through: :set_member_subjects

  validates_presence_of :project

  validates_uniqueness_of :display_name, scope: :project_id

  scope :expert_sets, -> { where(expert_set: true) }

  can_through_parent :project, :update, :show, :destroy, :index, :update_links,
    :destroy_links

  can_be_linked :project, :scope_for, :show, :user
  can_be_linked :workflow, :scope_for, :show, :user
  can_be_linked :set_member_subject, :scope_for, :update, :user

  def belongs_to_project?(other_project_id)
    project_id == other_project_id
  end
end
