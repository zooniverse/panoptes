class UserProjectPreferencePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      return scope.all if user.is_admin?
      scope.where(user_id: user.id)
    end
  end

  scope :index, :show, :update, :destroy, with: Scope
end
