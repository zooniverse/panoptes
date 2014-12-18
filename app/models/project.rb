class Project < ActiveRecord::Base
  include RoleControl::Controlled
  include RoleControl::Owned
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
  has_many :project_roles, class_name: "AccessControlList", as: :resource

  accepts_nested_attributes_for :project_contents

  ## TODO: Figure out how to do these validations
  #validates_uniqueness_of :name, case_sensitive: false, scope: :owner
  #validates_uniqueness_of :display_name, scope: :owner

  can_by_role :destroy, :update, :update_links, :destroy_links, roles: [ :owner,
                                                                         :collaborator ]
  can_by_role :show, :index, public: :public_scope, roles: [ :owner,
                                                             :collaborator,
                                                             :tester,
                                                             :translator,
                                                             :scientist,
                                                             :moderator ]

  can_be_linked :subject_set, :scope_for, :update, :groups
  can_be_linked :subject, :scope_for, :update, :groups
  can_be_linked :workflow, :scope_for, :update, :groups
  can_be_linked :user_group, :scope_for, :edit_project, :user

  preferences_model :user_project_preference
  
  def expert_classifier_level(classifier)
    expert_role = project_roles.where(user_group: classifier.identity_group)
                  .where.overlap(roles: EXPERT_ROLES)
                  .exists?
    expert_role ? :expert : nil
  end

  def expert_classifier?(classifier)
    !!expert_classifier_level(classifier)
  end
end
