class TagPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(_action)
      scope.all
    end
  end

  scope :index, :show, with: Scope
end
