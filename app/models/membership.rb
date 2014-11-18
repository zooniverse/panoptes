class Membership < ActiveRecord::Base
  extend ControlControl::Resource
  include RoleControl::RoleModel
  
  belongs_to :user_group
  belongs_to :user
  enum state: [:active, :invited, :inactive]

  roles_for :user, :user_group, valid_roles: [:group_admin,
                                              :project_editor,
                                              :collection_editor,
                                              :group_member]

  validates_presence_of :user, :user_group, :state

  can :update, :allowed_to_change?
  can :destroy, :allowed_to_change?
  can :show, :allowed_to_change?

  def self.scope_for(action, actor)
    case actor
    when ApiUser
      actor.user.memberships
    when UserGroup
      actor.memberships.active
    end
  end

  def self.can_create?(actor)
    !!actor
  end

  def allowed_to_change?(actor)
    actor.try(:owner) == user || (actor == user_group && active?)
  end
  
  def disable!
    inactive!
  end

  def enable!
    active!
  end
end
