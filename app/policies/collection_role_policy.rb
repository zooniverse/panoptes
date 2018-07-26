class CollectionRolePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      case action
      when :show, :index
        scope.where(resource: collection_scope(:show))
      when :update, :destroy
        scope.where(resource: collection_scope(:update))
      end
    end

    def collection_scope(action)
      CollectionPolicy.new(user, Collection).scope_for(action)
    end
  end

  scope :index, :show, :update, :destroy, with: Scope
end
