class Organization < ActiveRecord::Base
  Type = GraphQL::ObjectType.define do
    name "Organization"
    description "Organizations allow grouping of projects."

    field :id, !types.ID
    field :displayName, !types.String
    field :slug, !types.String

    field :classificationsCount, !types.Int do
      description "Aggregated number of classifications across all projects."
      resolve ->(obj, args, ctx) {
        obj.projects.sum(:classifications_count)
      }
    end

    field :retiredSubjectsCount, !types.Int, property: :retired_subjects_count do
      description "Aggregated number of classifications across all projects."
    end

    field :projects, types[Project::Type] do
      resolve ->(obj, args, ctx) {
        obj.projects.where(private: false)
      }
    end
  end

  include RoleControl::Owned
  include RoleControl::Controlled
  include Activatable
  include Linkable
  include SluggedName
  include Translatable

  scope :public_scope, -> { where(listed: true) }
  scope :private_scope, -> { where(listed: false) }

  has_many :projects
  has_many :acls, class_name: "AccessControlList", as: :resource, dependent: :destroy
  has_one :avatar, -> { where(type: "organization_avatar") }, class_name: "Medium", as: :linked
  has_one :background, -> { where(type: "organization_background") }, class_name: "Medium", as: :linked
  has_many :organization_roles, -> { where.not(roles: []) }, class_name: "AccessControlList", as: :resource
  has_many :pages, class_name: "OrganizationPage", dependent: :destroy
  has_many :tagged_resources, as: :resource
  has_many :tags, through: :tagged_resources

  accepts_nested_attributes_for :organization_contents

  can_by_role :destroy, :update, :update_links, :destroy_links, roles: [ :owner, :collaborator ]

  can_by_role :show, :index, :versions, :version, public: true,
    roles: [ :owner, :collaborator, :tester, :translator, :scientist, :moderator ]

  can_by_role :translate, roles: %i(owner translator collaborator)

  can_be_linked :project, :scope_for, :update, :user
  can_be_linked :access_control_list, :scope_for, :update, :user

  def retired_subjects_count
    projects.joins(:active_workflows).sum("workflows.retired_set_member_subjects_count")
  end
end
