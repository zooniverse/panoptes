class UserProjectPreference < ActiveRecord::Base
  include RoleControl::RoleModel
  belongs_to :user
  belongs_to :project

  roles_for :user, :project, valid_roles: [:collaborator,
                                           :translator,
                                           :tester,
                                           :scientist,
                                           :moderator]

  validates_presence_of :user, :project
end
