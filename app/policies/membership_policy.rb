class MembershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      return scope.all if user.is_admin?
      return scope.none unless user.logged_in?

      # Get the roles that are allowed to see groups for the current action
      roles = UserGroupPolicy.new(user, UserGroup).scope_klass_for(action).roles

      # Find all of the groups the current user is a member of, where their
      # membership role is one of the roles allowed for the action, as loaded above
      accessible_group_ids = user.user_groups.where("memberships.roles && ARRAY[?]::varchar[]", roles).select(:id)

      memberships_for_my_groups = scope.where(identity: false, user_group_id: accessible_group_ids)
      my_own_memberships = scope.where(identity: false, user_id: user.id)

      query = memberships_for_my_groups.or(my_own_memberships)

      case action
      when :show, :index
        public_memberships = scope.where(identity: false, state: Membership.states[:active])
                               .joins(:user_group).merge(UserGroup.where(private: false))
        query.union_all(public_memberships)
      else
        query
      end
    end
  end

  scope :index, :show, :update, :destroy, with: Scope

  def linkable_users
    User.all
  end
end
