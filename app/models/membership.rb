class Membership < ActiveRecord::Base
  include RoleControl::ParentalControlled

  belongs_to :user_group
  belongs_to :user
  enum state: [:active, :invited, :inactive]

  scope :identity, -> { where(identity: true,
                              state: states[:active],
                              roles: ["group_admin"]) }

  scope :not_identity, -> { where(identity: false) }

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

  def self.scope_for(action, user, opts={})
    return all if user.is_admin?
    roles, _ = parent_class.roles(action)
    accessible_groups = user.user_groups.where.overlap(memberships: {roles: roles})
    query = not_identity.where(user_group_id: accessible_groups)
            .or(not_identity.where(user_id: user.id))


    case action
    when :show, :index
      query.union_all(not_identity.where(state: states[:active])
                       .joins(:user_group).merge(UserGroup.public_scope))
    else
      query
    end
  end

  def disable!
    inactive!
  end

  def enable!
    active!
  end

  def group_admin?
    roles.include?("group_admin")
  end
end
