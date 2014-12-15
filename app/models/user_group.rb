class UserGroup < ActiveRecord::Base
  include RoleControl::Controlled
  include Activatable
  include Linkable

  has_many :memberships
  has_many :active_memberships, -> { active }, class_name: "Membership" 
  has_many :users, through: :active_memberships
  has_many :classifications
  has_many :access_control_lists
  
  has_many :owned_resources, -> { where(role: "owner") }, class_name: "AccessControlList"
  has_many :projects, through: :owned_resources, source: :resource, source_type: "Project"
  has_many :collections, through: :owned_resources, source: :resource, source_type: "Collection"
  has_many :subjects, through: :owned_resources, source: :resource, source_type: "Subject"

  validates :name, presence: true, uniqueness: { case_sensistive: false }

  before_validation :downcase_case_insensitive_fields

  scope :public_groups, -> { where(private: false) }

  can_by_role :show,
              public: :public_groups,
              role_association: :active_memberships,
              roles: [ :group_admin,
                       :project_editor,
                       :collection_editor,
                       :group_member ]
  
  can_by_role :update, role_association: :active_memberships,
              roles: [ :group_admin ]
              
  can_by_role :destroy, role_association: :active_memberships,
              roles: [ :group_admin ]

  def owns?(resource)
    owned_resources.exists?(resource_id: resource.id,
                            resource_type: resource.class.to_s)
  end

  private

  def downcase_case_insensitive_fields
    if name
      self.name = name.downcase
    end
  end
end
