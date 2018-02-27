class UserGroup < ActiveRecord::Base
  include RoleControl::Controlled
  include Activatable
  include Linkable
  include PgSearch

  has_many :memberships, dependent: :destroy
  has_many :active_memberships, -> { active.not_identity }, class_name: "Membership"
  has_one  :identity_membership, -> { identity }, class_name: "Membership"
  has_many :users, through: :memberships
  has_many :classifications, dependent: :restrict_with_exception
  has_many :access_control_lists, dependent: :destroy

  has_many :owned_resources, -> { where("roles && '{owner}'") },
           class_name: "AccessControlList"

  has_many :projects, through: :owned_resources, source: :resource,
           source_type: "Project"
  has_many :collections, through: :owned_resources, source: :resource,
           source_type: "Collection"

  validates :display_name, presence: true
  validates :name, presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: User::USER_LOGIN_REGEX }

  before_validation :default_display_name, on: [:create, :update]
  before_validation :default_join_token, on: [:create]

  scope :public_groups, -> { where(private: false) }

  can_by_role :show, :index,
              public: :public_groups,
              roles: [ :group_admin,
                       :project_editor,
                       :collection_editor,
                       :group_member ]

  can_by_role :update, :destroy, :update_links, :destroy_links,
              roles: [ :group_admin ]

  can_by_role :edit_project,
              roles: [ :group_admin, :project_editor ]

  can_by_role :edit_collection,
              roles: [ :group_admin, :collection_editor ]

  pg_search_scope :search_name,
    against: :display_name,
    using: :trigram,
    ranked_by: ":trigram"

  def self.memberships_query(action, target)
    target.memberships_for(action)
  end

  def self.joins_for
    :memberships
  end

  def self.private_query(action, target, roles)
    joins(:memberships).merge(target.memberships_for(action, self))
      .where(memberships: { identity: false })
  end

  def self.user_can_access_scope(private_query, public_flag)
    scope = where(id: private_query.select(:id))
    scope = scope.or(public_scope) if public_flag
    scope
  end

  def self.roles_allowed_to_access(action, klass=nil)
    roles = case action
            when :show, :index
              [:group_admin, :group_member]
            else
              [:group_admin]
            end
    roles.push :"#{klass.name.underscore}_editor" if klass
    roles
  end

  def owns?(resource)
    owned_resources.exists?(resource_id: resource.id,
                            resource_type: resource.class.to_s)
  end

  def has_admin?(user)
    membership_for_user(user)&.group_admin?
  end

  def membership_for_user(user)
    memberships.find_by(user_id: user.id)
  end

  def identity?
    !!identity_membership
  end

  def verify_join_token(token_to_verify)
    join_token.present? && join_token == token_to_verify
  end

  private

  def default_display_name
    self.display_name ||= name
  end

  def default_join_token
    self.join_token ||= SecureRandom.hex(8)
  end
end
