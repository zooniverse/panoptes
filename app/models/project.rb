class Project < ActiveRecord::Base
  include RoleControl::Owned
  include Activatable
  include ExtendedCacheKey
  include PgSearch
  include RankedModel
  include SluggedName
  include Translatable
  include Versioning

  EXPERT_ROLES = [:owner, :expert].freeze

  has_many :tutorials
  has_many :field_guides, dependent: :destroy
  belongs_to :organization
  # uses the activated_state enum on the workflow
  has_many :workflows,
    -> { where(serialize_with_project: true).active},
    dependent: :restrict_with_exception
  # use both the activated_state and active attribute on the workflow
  has_many :active_workflows,
    -> { where(active: true, serialize_with_project: true).active },
    class_name: "Workflow"
  has_many :subject_sets, dependent: :destroy
  has_many :classifications, dependent: :restrict_with_exception
  has_many :subjects, dependent: :restrict_with_exception
  has_many :acls, class_name: "AccessControlList", as: :resource, dependent: :destroy
  has_many :project_roles, -> { where.not("access_control_lists.roles = '{}'") }, class_name: "AccessControlList", as: :resource
  has_one :avatar, -> { where(type: "project_avatar") }, class_name: "Medium", as: :linked
  has_one :background, -> { where(type: "project_background") }, class_name: "Medium",
    as: :linked
  has_one :classifications_export, -> { where(type: "project_classifications_export").order(created_at: :desc) },
    class_name: "Medium", as: :linked
  has_one :subjects_export, -> { where(type: "project_subjects_export").order(created_at: :desc) },
    class_name: "Medium", as: :linked
  has_one :workflows_export, -> { where(type: "project_workflows_export").order(created_at: :desc) },
    class_name: "Medium", as: :linked
  has_one :workflow_contents_export, -> { where(type: "project_workflow_contents_export").order(created_at: :desc) },
    class_name: "Medium", as: :linked
  has_many :attached_images, -> { where(type: "project_attached_image") }, class_name: "Medium",
    as: :linked
  has_many :pages, class_name: "ProjectPage", dependent: :destroy
  has_many :tagged_resources, as: :resource
  has_many :tags, through: :tagged_resources
  has_many :first_time_users, class_name: "User", foreign_key: 'project_id', inverse_of: :signup_project, dependent: :restrict_with_exception

  has_many :project_versions, dependent: :destroy

  versioned association: :project_versions, attributes: %w(private live beta_requested beta_approved launch_requested launch_approved display_name description workflow_description introduction url_labels researcher_quote)

  enum state: [:paused, :finished]

  cache_by_resource_method :subjects_count, :retired_subjects_count, :finished?

  validates_inclusion_of :private, :live, in: [true, false], message: "must be true or false"

  ## TODO: This potential has locking issues
  validates_with UniqueForOwnerValidator

  after_save :save_version
  after_update :send_notifications

  # Still needed for HttpCacheable
  scope :private_scope, -> { where(private: true) }

  scope :launched, -> { where("launch_approved IS TRUE") }
  scope :featured, -> { where(featured: true) }

  alias_attribute :title, :display_name

  pg_search_scope :search_display_name,
    against: :display_name,
    using: {
      tsearch: {
        dictionary: "english",
        tsvector_column: "tsv"
      },
      trigram: {}
    },
    :ranked_by => ":tsearch + (0.25 * :trigram)"

  ranks :launched_row_order
  ranks :beta_row_order

  def self.translatable_attributes
    %i(display_name title description workflow_description introduction researcher_quote url_labels)
  end

  def available_languages
    [primary_language] | configuration.fetch('languages', [])
  end

  def expert_classifier_level(classifier)
    expert_roles = project_roles.where(user_group: classifier.identity_group)
      .where("roles && ARRAY[?]::varchar[]", EXPERT_ROLES)
    if roles = expert_roles.first.try(:roles)
      (EXPERT_ROLES & roles.map(&:to_sym)).first
    end
  end

  def expert_classifier?(classifier)
    !!expert_classifier_level(classifier)
  end

  def owners_and_collaborators
    users_with_project_roles(%w(owner collaborator)).select(:id)
  end

  def create_talk_admin(client)
    owners_and_collaborators.each do |user|
      client.roles.create(name: 'admin',
                          user_id: user.id,
                          section: "project-#{id}")
    end
  end

  def send_notifications
    if Panoptes.project_request.recipients
      request_type = if beta_requested_changed? && beta_requested
                       "beta"
                     elsif launch_requested_changed? && launch_requested
                       "launch"
                     end
      ProjectRequestEmailWorker.perform_async(request_type, id) if request_type
    end
  end

  def subjects_count
    @subjects_count ||=
      if active_workflows.loaded?
        active_workflows.inject(0) do |sum,workflow|
          sum + workflow.real_set_member_subjects_count
        end
      else
        active_workflows.sum :real_set_member_subjects_count
      end
  end

  def retired_subjects_count
    @retired_subject_count ||= if active_workflows.loaded?
      active_workflows.inject(0) do |sum,w|
        sum + w.retired_set_member_subjects_count
      end
    else
      active_workflows.sum :retired_set_member_subjects_count
    end
  end

  def finished?
    super ? super : active_workflows.all?(&:finished?)
  end

  def state
    if self[:state]
      super
    else
      live ? "live" : "development"
    end
  end

  def users_with_project_roles(roles)
    project_roles = acls.where(
      "access_control_lists.roles && ARRAY[?]::varchar[]",
      roles
    )
    User.joins(user_groups: :access_control_lists).merge(project_roles)
  end

  def communication_emails
    users_with_project_roles(%w(owner communications)).pluck(:email)
  end
end
