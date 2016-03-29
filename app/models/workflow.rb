class Workflow < ActiveRecord::Base
  include Linkable
  include Translatable
  include RoleControl::ParentalControlled
  include SubjectCounts
  include ExtendedCacheKey
  include RankedModel
  include CacheModelVersion

  has_paper_trail only: [:tasks, :grouped, :pairwise, :prioritized]

  belongs_to :project
  has_many :subject_workflow_counts, dependent: :destroy
  has_many :subject_sets_workflows, dependent: :destroy
  has_many :subject_sets, through: :subject_sets_workflows
  has_many :set_member_subjects, through: :subject_sets
  has_many :subjects, through: :set_member_subjects
  has_many :classifications
  has_many :user_seen_subjects
  has_many :subject_queues, dependent: :destroy
  has_many :workflow_tutorials, dependent: :destroy
  has_many :tutorials, through: :workflow_tutorials
  has_many :attached_images, -> { where(type: "workflow_attached_image") }, class_name: "Medium",
    as: :linked
  has_and_belongs_to_many :expert_subject_sets, -> { expert_sets }, class_name: "SubjectSet"
  belongs_to :tutorial_subject, class_name: "Subject"

  cache_by_association :workflow_contents
  cache_by_resource_method :subjects_count, :finished?

  DEFAULT_RETIREMENT_OPTIONS = {
    'criteria' => 'classification_count',
    'options' => {'count' => 15}
  }

  validates_presence_of :project, :display_name

  validate do |workflow|
    criteria = RetirementSchemes::CRITERIA.keys
    unless workflow.retirement.empty? || criteria.include?(workflow.retirement['criteria'])
      workflow.errors.add(:"retirement.criteria", "Retirement criteria must be one of #{criteria.join(', ')}")
    end
  end

  can_through_parent :project, :update, :index, :show, :destroy, :update_links,
    :destroy_links, :translate, :versions, :version, :retire_subject

  can_be_linked :subject_set, :same_project?, :model
  can_be_linked :subject_queue, :scope_for, :update, :user
  can_be_linked :aggregation, :scope_for, :update, :user

  ranks :display_order, with_same: :project_id

  def self.same_project?(subject_set)
    where(project: subject_set.project)
  end

  def tasks
    read_attribute(:tasks).with_indifferent_access
  end

  def retired_subjects
    subject_workflow_counts.retired.includes(:subject).map(&:subject)
  end

  def retire_subject(subject_id)
    if set_member_subjects.where(subject_id: subject_id).any?
      count = subject_workflow_counts.where(subject_id: subject_id, workflow_id: id).first_or_create!
      count.retire!
    end
  end

  def retirement_scheme
    criteria = retirement_with_defaults.fetch('criteria')
    options = retirement_with_defaults.fetch('options')
    scheme_class = RetirementSchemes.for(criteria).new(options)
  end

  def retirement_with_defaults
    self.retirement.presence || DEFAULT_RETIREMENT_OPTIONS
  end

  def retired_subjects_count
    retired_set_member_subjects_count
  end

  def selection_strategy
    configuration.with_indifferent_access[:selection_strategy].try(:to_sym)
  end

  def cellect_size_subject_space?
    set_member_subjects.count >= Panoptes.cellect_min_pool_size
  end

  def using_cellect?
    case
    when selection_strategy == :cellect
      true
    when selection_strategy
      false
    else
      cellect_size_subject_space?
    end
  end
end
