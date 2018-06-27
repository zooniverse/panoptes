class UserGroupPolicy < ApplicationPolicy
  # The old can_by_role scopes used to take into accuont a `project_editor` and `collection_editor`.
  # Neither of these exist in the database, and therefore these are no longer included now.

  class Scope < Scope
    def private_query(action, roles)
      scope.joins(:memberships).merge(user.memberships_for(action, model))
        .where(memberships: { identity: false })
    end

    def user_can_access_scope(private_query)
      accessible = scope
      accessible = accessible.where(id: private_query.select(:id))
      accessible = accessible.or(public_scope) if public_flag
      accessible
    end
  end

  class ReadScope < Scope
    roles_for_private_scope %i(group_admin group_member)

    def public_scope
      scope.where(private: false)
    end
  end

  class WriteScope < Scope
    roles_for_private_scope %i(group_admin)
  end

  scope :index, :show, :recents, with: ReadScope
  scope :update, :destroy, :update_links, :destroy_links, with: WriteScope
end
