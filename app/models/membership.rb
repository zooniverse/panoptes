class Membership < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :user
  enum state: [:active, :invited, :inactive]

  scope :identity, -> { where(identity: true,
                              state: states[:active],
                              roles: ["group_admin"]) }

  validates_presence_of :user, unless: :identity
  validates_associated :user_group

  def self.scope_for(action, user, opts={})
    case action
    when :show, :index
      where(user_group: UserGroup.public_groups)
        .union(where(user: user.user))
        .union(where(user: user.groups_for(:show)))
    when :update, :destroy
      where(user_group: user.groups_for(:update)).union(where(user: user.user))
    end.where(identity: false)
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
