class Membership < ActiveRecord::Base
  include RoleControl::ParentalControlled
  
  belongs_to :user_group
  belongs_to :user
  enum state: [:active, :invited, :inactive]

  scope :identity, -> { where(identity: true,
                              state: states[:active],
                              roles: ["group_admin"]) }

  validates_presence_of :user, unless: :identity
  validates_associated :user_group
  validates_presence_of :state, :user_group

  can_through_parent :user_group, :update, :index, :show, :destroy, :update_links,
                     :destroy_links

  scope :private_scope, -> { joins(@parent).merge(parent_class.private_scope) }
  scope :public_scope, -> {
    joins(@parent).where(state: states[:active]).merge(parent_class.public_scope)
  }

  def self.joins_for
    @parent
  end

  def self.private_query(query, action, target, roles)
    user = target.user
    with(groups: user.user_groups.where.overlap(memberships: {roles: roles}))
      .joins("JOIN \"groups\" ON \"memberships\".\"user_group_id\" = \"groups\".\"id\"")
      .where.not(user: user)
      .union_all(user.memberships)
  end

  def self.scope_for(action, target, opts={})
    super.where(identity: false)
  end
  
  def disable!
    inactive!
  end

  def enable!
    active!
  end
end
