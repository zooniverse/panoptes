class Project < ActiveRecord::Base
  include RoleControl::Owned
  include RoleControl::Controlled
  include SubjectCounts
  include Activatable
  include Linkable
  include Translatable
  include PreferencesLink

  EXPERT_ROLES = [:expert, :owner]

  has_many :workflows
  has_many :subject_sets
  has_many :classifications
  has_many :subjects
  has_many :project_roles, -> { where.not(roles: []) }, class_name: "AccessControlList", as: :resource

  accepts_nested_attributes_for :project_contents

  validates_inclusion_of :private, :live, in: [true, false], message: "must be true or false"

  ## TODO: This potential has locking issues
  validates_with UniqueForOwnerValidator

  can_by_role :destroy, :update, :update_links, :destroy_links, roles: [ :owner,
                                                                         :collaborator ]
  can_by_role :show, :index, :versions, :version,
              public: true, roles: [ :owner,
                                              :collaborator,
                                              :tester,
                                              :translator,
                                              :scientist,
                                              :moderator ]

  can_by_role :translate, roles: [ :owner, :translator ]

  can_be_linked :subject_set, :scope_for, :update, :user
  can_be_linked :subject, :scope_for, :update, :user

  can_be_linked :workflow, :scope_for, :update, :user
  can_be_linked :user_group, :scope_for, :edit_project, :user

  preferences_model :user_project_preference

  def expert_classifier_level(classifier)
    expert_role = project_roles.where(user_group: classifier.identity_group)
                  .where.overlap(roles: EXPERT_ROLES)
    expert_role.first.try(:roles).try(:first).try(:to_sym)
  end

  def expert_classifier?(classifier)
    !!expert_classifier_level(classifier)
  end
end
