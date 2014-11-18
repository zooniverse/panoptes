class Project < ActiveRecord::Base
  include RoleControl::Controlled
  include RoleControl::Ownable
  include RoleControl::Adminable
  include SubjectCounts
  include Activatable
  include Linkable
  include Translatable
  include PreferencesLink

  EXPERT_ROLES = [:expert]

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

  preferences_model :user_project_preference
  
  def self.translation_scope
    @translation_scope ||= RoleControl::RoleScope.new(["translator"], false, self)
  end

  def expert_classifier_level(classifier)
    return :owner if classifier == owner
    expert_role = project_roles.where(user_id: classifier.id)
      .where("roles @> ARRAY[?]::varchar[]", EXPERT_ROLES)
      .exists?
    expert_role ? :expert : nil
  end

  def expert_classifier?(classifier)
    !!expert_classifier_level(classifier)
  end
end
