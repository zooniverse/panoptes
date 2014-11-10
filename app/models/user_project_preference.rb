class UserProjectPreference < ActiveRecord::Base
  extend ControlControl::Resource
  include RoleControl::Adminable
  include RoleControl::RoleModel

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

  can :update, :allowed_to_change?
  can :destroy, :allowed_to_change?
  can :show, :allowed_to_change?
  can :update_roles, proc { |actor| project.can_update?(actor) }
  can :update_preferences, proc { |actor| user == actor.try(:user) }

  def self.visible_to(actor, as_admin: false)
    UserProjectPreferenceVisibilityQuery.new(actor, self).build(as_admin)
  end

  def self.can_create?(actor)
    actor.try(:logged_in?)
  end

  def allowed_to_change?(actor)
    can_update_preferences?(actor) || can_update_roles?(actor)
  end
end
