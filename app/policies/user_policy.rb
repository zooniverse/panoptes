class UserPolicy < ApplicationPolicy
  class ReadScope < Scope
    def resolve(action)
      return scope.all if user.is_admin?
      scope.where(ouroboros_created: false).merge(scope.active)
    end
  end

  class WriteScope < Scope
    def resolve(action)
      return scope.all if user.is_admin?
      scope.where(id: user.id)
    end
  end

  scope :index, :show, :recents, with: ReadScope
  scope :update, :deactivate, :destroy, with: WriteScope
end
