class UserGroup < ActiveRecord::Base
  include RoleControl::Controlled
  include Nameable
  include Activatable
  include RoleControl::Owner
  include RoleControl::Adminable
  include Linkable

  attr_accessible :name, :display_name

  owns :projects
  owns :collections
  owns :subjects

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

  validates :name, presence: true, uniqueness: true

  before_validation :downcase_case_insensitive_fields

  can_by_role :show, roles: [ :group_admin, :project_editor, :collection_editor, :group_member ]
  can_by_role :update, roles: [ :group_admin ]
  can_by_role :destroy, roles: [ :group_admin ]

  can_by_role :update, act_as: Collection, roles: [ :group_admin, :collection_editor ]
  can_by_role :destroy, act_as: Collection, roles: [ :group_admin, :collection_editor ]
  can_by_role :create, act_as: Collection, roles: [ :group_admin, :collection_editor ]

  can_by_role :update, act_as: Project, roles: [ :group_admin, :project_editor ]
  can_by_role :destroy, act_as: Project, roles: [ :group_admin, :project_editor ]
  can_by_role :create, act_as: Project, roles: [ :group_admin, :project_editor ]

  private

  def downcase_case_insensitive_fields
    if name
      self.name = name.downcase
    end
  end
end
