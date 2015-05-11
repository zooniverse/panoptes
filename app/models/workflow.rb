class Workflow < ActiveRecord::Base
  include Linkable
  include Translatable
  include RoleControl::ParentalControlled
  include SubjectCounts
  include ExtendedCacheKey

  has_paper_trail only: [:tasks, :grouped, :pairwise, :prioritized]

  belongs_to :project
  has_many :subject_workflow_counts, dependent: :destroy
  has_many :subject_sets_workflows, dependent: :destroy
  has_many :subject_sets, through: :subject_sets_workflows
  has_many :set_member_subjects, through: :subject_sets
  has_many :classifications
  has_many :user_seen_subjects
  has_many :subject_queues, dependent: :destroy
  has_and_belongs_to_many :expert_subject_sets, -> { expert_sets }, class_name: "SubjectSet"
  belongs_to :tutorial_subject, class_name: "Subject"

  cache_by_association :workflow_contents
  cache_by_resource_method :subjects_count, :finished?

  DEFAULT_CRITERIA = 'classification_count'
  DEFAULT_OPTS = { 'count' => 15 }

  validates_presence_of :project

  validate do |workflow|
    criteria = %w(classification_count)
    unless workflow.retirement.empty? || criteria.include?(workflow.retirement['criteria'])
      workflow.errors.add(:"retirement.criteria", "Retirement criteria must be one of #{criteria.join(', ')}")
    end
  end

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

  def retirement_scheme
    case retirement.fetch('criteria', DEFAULT_CRITERIA)
    when 'classification_count'
      params = retirement.fetch('options', DEFAULT_OPTS).values_at('count')
      RetirementSchemes::ClassificationCount.new(*params)
    else
      raise StandardError, 'invalid retirement scheme'
    end
  end

  def retired_subjects_count
    retired_set_member_subjects_count
  end
end
