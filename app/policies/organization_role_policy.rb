class OrganizationRolePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      case action
      when :show, :index
        scope.where(resource: organization_scope(:show))
      when :update, :destroy
        scope.where(resource: organization_scope(:update))
      end
    end

    def organization_scope(action)
      OrganizationPolicy.new(user, Organization).scope_for(action)
    end
  end

  scope :index, :show, :update, :destroy, with: Scope
end
