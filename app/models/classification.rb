class Classification < ActiveRecord::Base
  class MissingParameter < StandardError; end

  belongs_to :project
  belongs_to :user
  belongs_to :workflow
  belongs_to :user_group

  has_one :export_row, class_name: "ClassificationExportRow"

  has_many :recents, dependent: :destroy

  has_and_belongs_to_many :subjects,
    join_table: :classification_subjects,
    validate: false

  enum expert_classifier: [:expert, :owner]

  validates_presence_of :subjects, :project,
    :workflow, :annotations, :user_ip, :workflow_version

  validates :user, presence: {message: "Only logged in users can store incomplete classifications"}, if: :incomplete?
  validate :metadata, :validate_metadata
  validate :validate_gold_standard

  scope :incomplete, -> { where("completed IS FALSE") }
  scope :created_by, -> (user) { where(user_id: user.id) }
  scope :complete, -> { where(completed: true) }
  scope :gold_standard, -> { where("gold_standard IS TRUE") }
  scope :after_id, -> (last_id) { where("classifications.id > ?", last_id) }

  def self.scope_for(action, user, opts={})
    return all if user.is_admin? && action != :gold_standard
    case action
    when :index
      complete.merge(created_by(user))
    when :show
      created_by(user)
    when :update, :destroy
      incomplete_for_user(user)
    when :incomplete
      incomplete_for_user(user)
    when :project
      classifications_for_project(user, opts)
    when :gold_standard
      gold_standard_for_user(user, opts)
    else
      none
    end
  end

  def self.joins_classification_subjects
    joins("INNER JOIN classification_subjects ON classifications.id = classification_subjects.classification_id")
  end

  def self.incomplete_for_user(user)
    incomplete.merge(created_by(user))
  end

  def self.gold_standard_for_user(user, opts)
    return GoldStandardAnnotation.all if user.is_admin?

    public_workflows = Workflow.where("public_gold_standard IS TRUE")
    if opts[:workflow_id]
      public_workflows = public_workflows.where(id: opts[:workflow_id])
    end
    public_workflow_ids = public_workflows.select(:id)
    GoldStandardAnnotation
      .where(workflow_id: public_workflow_ids)
      .order(id: :asc)
  end

  def self.classifications_for_project(user, opts)
    if opts[:last_id] && !opts[:project_id]
      raise Classification::MissingParameter.new("Project ID required if last_id is included")
    end
    projects = Project.scope_for(:update, user)
    projects = projects.where(id: opts[:project_id]) if opts[:project_id]
    scope = where(project_id: projects.select(:id))
    scope = scope.after_id(opts[:last_id]) if opts[:last_id]
    scope
  end

  def created_and_incomplete?(actor)
    creator?(actor) && incomplete?
  end

  def creator?(actor)
    user == actor.user
  end

  def complete?
    completed
  end

  def incomplete?
    !completed
  end

  def anonymous?
    !user
  end

  def seen_before?
    if seen_before = metadata[:seen_before]
      !!"#{seen_before}".match(/^true$/i)
    else
      false
    end
  end

  def metadata
    read_attribute(:metadata).with_indifferent_access
  end

  private

  def validate_metadata
    validate_seen_before
    required_metadata_present
  end

  def required_metadata_present
    %i(started_at finished_at user_language user_agent).each do |key|
      unless metadata.has_key? key
        errors.add(:metadata, "must have #{key} metadata")
      end
    end
  end

  def validate_seen_before
    if metadata.has_key?(:seen_before) && !seen_before?
      errors.add(:metadata, "seen_before attribute can only be set to 'true'")
    end
  end

  def validate_gold_standard
    ClassificationValidator.new(self).validate_gold_standard
  end
end
