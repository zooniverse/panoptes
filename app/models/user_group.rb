class UserGroup < ActiveRecord::Base
  include RoleControl::Controlled
  include Activatable
  include Linkable

  has_many :memberships
  has_many :active_memberships, -> { active.where(identity: false) },
           class_name: "Membership" 
  has_many :users, through: :memberships
  has_many :classifications
  has_many :access_control_lists
  
  has_many :owned_resources, -> { where(roles: ["owner"]) },
           class_name: "AccessControlList"
  
  has_many :projects, through: :owned_resources, source: :resource,
           source_type: "Project"
  has_many :collections, through: :owned_resources, source: :resource,
           source_type: "Collection"

  validates :display_name, presence: true, format: { without: /\$|@|\s+/ }
  validates :name, presence: true, uniqueness: true

  before_validation :downcase_case_insensitive_fields

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

  def identity?
    !!memberships.where(identity: true).pluck(:identity).first
  end

  private
  
  def downcase_case_insensitive_fields
    if name.nil? && display_name
      self.name = display_name.downcase
    end
  end
end
