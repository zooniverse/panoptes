class UserGroup < ActiveRecord::Base
  extend RoleControl::ActAsControlled
  include Nameable
  include Activatable
  include ControlControl::Owner

  attr_accessible :name, :display_name

  owns :projects
  owns :collections
  owns :subjects

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

  validates :name, presence: true, uniqueness: true

  before_validation :downcase_case_insensitive_fields

  can_by_role :show, :group_admin, :project_edit, :collection_editor, :group_member
  can_by_role :update, :group_admin
  can_by_role :destroy, :group_admin

  can_as_by_role :show, roles: [ :group_admin, :project_edit, :collection_editor, :group_member ]

  can_as_by_role :update, target: Collection, roles: [ :group_admin, :collection_editor ]
  can_as_by_role :destroy, target: Collection, roles: [ :group_admin, :collection_editor ]
  can_as_by_role :create, target: Collection, roles: [ :group_admin, :collection_editor ]

  can_as_by_role :update, target: Project, roles: [ :group_admin, :project_editor ]
  can_as_by_role :destroy, target: Project, roles: [ :group_admin, :project_editor ]
  can_as_by_role :create, target: Project, roles: [ :group_admin, :project_editor ]

  private

  def downcase_case_insensitive_fields
    if name
      self.name = name.downcase
    end
  end
end
