class Workflow < ActiveRecord::Base
  include Activatable
  include Linkable
  include Translatable
  include RoleControl::ParentalControlled
  include ExtendedCacheKey
  include RankedModel
  include CacheModelVersion
  include ModelCacheKey

  has_paper_trail only: [:tasks, :grouped, :pairwise, :prioritized]

  belongs_to :project
  has_many :subject_workflow_statuses, dependent: :destroy
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
  has_one :classifications_export, -> { where(type: "workflow_classifications_export").order(created_at: :desc) },
      class_name: "Medium", as: :linked
  has_and_belongs_to_many :expert_subject_sets, -> { expert_sets }, class_name: "SubjectSet"
  belongs_to :tutorial_subject, class_name: "Subject"

  # TODO: remove this association from the cache key
  cache_by_resource_method :subjects_count, :finished?

  enum subject_selection_strategy: [:default, :cellect, :designator, :builtin]

  scope :using_cellect, -> { where(subject_selection_strategy: subject_selection_strategies[:cellect]) }

  DEFAULT_RETIREMENT_OPTIONS = {
    'criteria' => 'classification_count',
    'options' => {'count' => 15}
  }.freeze

  validates_presence_of :project, :display_name

  validate do |workflow|
    criteria = RetirementSchemes::CRITERIA.keys
    unless workflow.retirement.empty? || criteria.include?(workflow.retirement['criteria'])
      workflow.errors.add(:"retirement.criteria", "Retirement criteria must be one of #{criteria.join(', ')}")
    end
  end

  can_through_parent :project, :update, :index, :show, :destroy, :update_links,
    :destroy_links, :translate, :versions, :version, :retire_subject, :create_classifications_export

  can_be_linked :subject_set, :same_project?, :model
  can_be_linked :subject_queue, :scope_for, :update, :user
  can_be_linked :aggregation, :scope_for, :update, :user

  ranks :display_order, with_same: :project_id

  delegate :owner, to: :project

  def self.same_project?(subject_set)
    where(project: subject_set.project)
  end

  def tasks
    read_attribute(:tasks).with_indifferent_access
  end

  def retired_subjects
    subject_workflow_statuses.retired.includes(:subject).map(&:subject)
  end

  def retire_subject(subject_id, reason=nil)
    count = subject_workflow_statuses.where(subject_id: subject_id).first_or_create!
    count.retire!(reason)
  end

  def retirement_scheme
    criteria = retirement_with_defaults.fetch('criteria')
    options = retirement_with_defaults.fetch('options')
    scheme_class = RetirementSchemes.for(criteria).new(options)
  end

  def retirement_with_defaults
    self.retirement.presence || DEFAULT_RETIREMENT_OPTIONS
  end

  def subject_selector
    @subject_selector ||=
      case
      when subject_selection_strategy == "builtin"
        Subjects::BuiltInSelector.new(self)
      when subject_selection_strategy == "cellect"
        Subjects::CellectSelector.new(self)
      when subject_selection_strategy == "designator"
        Subjects::DesignatorSelector.new(self)
      else
        Subjects::DesignatorSelector.new(self)
      end
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
    @finished ||= case
      when subject_sets.empty? || subjects_count == 0
        false
      when finished_at.present?
        true
      else
        retired_subjects_count >= subjects_count
      end
  end
end
