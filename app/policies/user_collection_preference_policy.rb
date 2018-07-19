class UserCollectionPreferencePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      return scope.all if user.is_admin?
      scope.where(user_id: user.id)
    end
  end

  scope :index, :show, :update, :destroy, with: Scope

  def linkable_collections
    policy_for(Collection).scope_for(:show)
  end

  def linkable_users
    User.all
  end
end
