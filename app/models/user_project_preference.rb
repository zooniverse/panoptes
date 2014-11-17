class UserProjectPreference < ActiveRecord::Base
  extend ControlControl::Resource
  include RoleControl::Adminable
  include RoleControl::RoleModel
  include Preferences
  
  belongs_to :user, dependent: :destroy
  belongs_to :project, dependent: :destroy

  attr_accessible :roles, :preferences, :email_communication

  roles_for :user, :project, valid_roles: [:expert,
                                           :collaborator,
                                           :translator,
                                           :tester,
                                           :scientist,
                                           :moderator]

  validates_presence_of :user, :project

  visibility_query UserProjectPreferenceVisibilityQuery
end
