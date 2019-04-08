class Workflow < ActiveRecord::Base
  include Activatable
  include ExtendedCacheKey
  include RankedModel
  include ModelCacheKey
  include Translatable
  include Versioning

  versioned association: :workflow_versions, attributes: %w(tasks first_task strings major_version minor_version)

  belongs_to :project
  has_many :subject_workflow_statuses, dependent: :destroy
  has_many :subject_sets_workflows, dependent: :destroy
  has_many :subject_sets, through: :subject_sets_workflows
  has_many :set_member_subjects, through: :subject_sets
  has_many :subjects, through: :set_member_subjects
  has_many :classifications, dependent: :restrict_with_exception
  has_many :user_seen_subjects, dependent: :destroy
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

  enum subject_selection_strategy: %i{default cellect designator builtin}

  max_paginates_per 25

  DEFAULT_RETIREMENT_OPTIONS = {
    'criteria' => 'classification_count',
    'options' => {'count' => 15}
  }.freeze

  JSON_ATTRIBUTES = %w(tasks retirement aggregation configuration strings steps).freeze

  # Used by HttpCacheable
  scope :private_scope, -> { where(project_id: Project.private_scope) }

  validates_presence_of :project, :display_name

  validate :retirement_config

  has_many :workflow_versions, dependent: :destroy
  belongs_to :published_version, class_name: "WorkflowVersion"

  def publish!
    update!(published_version: workflow_versions.order(:id).last)
  end

  def latest_version
    self
  end

  ranks :display_order, with_same: :project_id

  delegate :owner, to: :project
  delegate :communication_emails, to: :project

  def self.translatable_attributes
    %i(display_name strings)
  end

  before_save :update_version

  def update_version
    if (changes.keys & %w(tasks grouped pairwise prioritized first_task)).present?
      self.major_version += 1
    end

    if changes.include? :strings
      self.minor_version += 1
    end

    if new_record?
      self.major_version = 1 if major_version < 1
      self.minor_version = 1 if minor_version < 1
    end
  end

  # select a workflow without any json attributes (some can be very large)
  # this can be used generally in most workers
  # access to non-loaded attributes will raise an undefined_error
  # workflow.reload can be used to retrieve the missing attributes if needed
  #
  # Longer term the large json attributes could be sliced out to their own table
  # and linked to the workflow as an assocaition
  def self.find_without_json_attrs(id)
    non_json_attrs = Workflow.attribute_names - JSON_ATTRIBUTES
    select(*non_json_attrs).find(id)
  end

  def self.same_project?(subject_set)
    where(project: subject_set.project)
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
      case subject_selection_strategy
      when "builtin"
        Subjects::BuiltInSelector.new(self)
      when "cellect"
        Subjects::CellectSelector.new(self)
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

  def retirement_config
    RetirementValidator.new(self).validate
  end
end
