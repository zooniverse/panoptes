class Project < ActiveRecord::Base
  include RoleControl::Controlled
  include RoleControl::Ownable
  include RoleControl::Adminable
  include SubjectCounts
  include Activatable
  include Translatable
  include Linkable

  attr_accessible :name, :display_name, :owner, :primary_language,
    :project_contents, :avatar, :background_image

  has_many :workflows
  has_many :subject_sets
  has_many :classifications
  has_many :subjects
  has_many :project_roles, -> { where.not(roles: []) }, class_name: "UserProjectPreference"

  validates_uniqueness_of :name, case_sensitive: false, scope: :owner
  validates_uniqueness_of :display_name, scope: :owner

  can_by_role :update, roles: [ :collaborator ] 
  can_by_role :show, public: true, roles: :visible_to

  can_be_linked :subject_set, :scope_for, :update, :actor
  can_be_linked :subject, :scope_for, :update, :actor
  can_be_linked :workflow, :scope_for, :update, :actor
  can_be_linked :user_project_preference, :preference_scope, :actor
  can_be_linked :project_content, :translatable_by, :actor

  # Users can add preferences for any project they can see. Roles may
  # only be added by a User that has edit permissions for a project
  def self.preference_scope(actor, type)
    case type
    when :roles
      scope_for(:update, actor)
    when :preferences
      scope_for(:show, actor)
    end
  end

  def self.translation_scope
    @translation_scope ||= RoleControl::RoleScope.new(["translator"], false, self)
  end

  def self.translatable_by(actor)
    translation_scope.build(actor)
  end

  def is_translator?(actor)
    self.class.translatable_by(actor).exists?(id)
  end
end
