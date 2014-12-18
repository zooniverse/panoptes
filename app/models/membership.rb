class Membership < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :user
  enum state: [:active, :invited, :inactive]

  scope :identity, -> { where(identity: true,
                              state: states[:active],
                              roles: ["group_admin"]) }

  validates_presence_of :user, unless: :identity
  validates_associated :user_group

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
