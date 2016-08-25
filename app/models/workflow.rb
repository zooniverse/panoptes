class Workflow < ActiveRecord::Base
  include Activatable
  include Linkable
  include Translatable
  include RoleControl::ParentalControlled
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
  has_many :classifications, dependent: :restrict_with_exception
  has_many :user_seen_subjects, dependent: :destroy
  has_many :subject_queues, dependent: :destroy
  has_many :workflow_tutorials, dependent: :destroy
  has_many :tutorials, through: :workflow_tutorials
  has_many :aggregations, dependent: :destroy
  has_many :attached_images, -> { where(type: "workflow_attached_image") }, class_name: "Medium",
    as: :linked
  has_and_belongs_to_many :expert_subject_sets, -> { expert_sets }, class_name: "SubjectSet"
  belongs_to :tutorial_subject, class_name: "Subject"

  cache_by_association :workflow_contents
  cache_by_resource_method :subjects_count, :finished?

  enum subject_selection_strategy: [:default, :cellect, :cellect_ex]

  scope :using_cellect, -> { where(subject_selection_strategy: subject_selection_strategies[:cellect]) }

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

  def retire_subject(subject_id, reason=nil)
    if set_member_subjects.where(subject_id: subject_id).any?
      count = subject_workflow_counts.where(subject_id: subject_id, workflow_id: id).first_or_create!
      count.retire!(reason)
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

  def cellect_size_subject_space?
    set_member_subjects.count >= Panoptes.cellect_min_pool_size
  end

  def using_cellect?
    subject_selection_strategy.to_s == "cellect" || cellect_size_subject_space?
  end

  def subjects_count
    @subject_count ||= if subject_sets.loaded?
      subject_sets.inject(0) do |sum,set|
        sum + set.set_member_subjects_count
      end
    else
      subject_sets.sum :set_member_subjects_count
    end
  end

  def retired_subjects_count
    retired_set_member_subjects_count
  end

  def finished?
    @finished ||= if subject_sets.empty? || subjects_count == 0
      false
    else
      finished_at.present?
    end
  end
end
