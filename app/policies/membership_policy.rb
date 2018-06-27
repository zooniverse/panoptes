class MembershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      return scope.all if user.is_admin?
      return scope.none unless user.logged_in?

      roles, _ = UserGroupPolicy.new(user, UserGroup).scope_klass_for(action).roles
      # The setup here is that you are allowed to see all of the memberships in groups that you
      # are in, but not modify them.
      accessible_group_ids = user.user_groups.where("memberships.roles && ARRAY[?]::varchar[]", roles).select(:id)

      query = scope.where(identity: false, user_group_id: accessible_group_ids)
                .or(scope.where(identity: false, user_id: user.id))

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

  scope :index, :show, :update, :destroy, :update_links, :destroy_links, with: Scope
end
