class Membership < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :user
  enum state: [:active, :invited, :inactive]

  scope :identity, -> { where(identity: true,
                              state: states[:active],
                              roles: ["group_admin"]) }

  validates_presence_of :user, unless: :identity
  validates_associated :user_group
  validates_presence_of :state, :user_group

  def self.scope_for(action, user, opts={})
    case action
    when :show, :index
      where(user_group: UserGroup.public_groups, state: states[:active])
        .union(where(user: user.user))
        .union(where(user_group: user.groups_for(:show)))
    when :update, :destroy
      where(user_group: user.groups_for(:update)).where.not(state: states[:invited])
        .union(where(user: user.user))
    end.where(identity: false)
  end

  def disable!
    inactive!
  end

  def enable!
    active!
  end
end
