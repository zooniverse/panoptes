class ProjectRolePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      case action
      when :show, :index
        scope.where(resource: project_scope(:show))
      when :update, :destroy
        scope.where(resource: project_scope(:update))
      end
    end

    def project_scope(action)
      ProjectPolicy.new(user, Project).scope_for(action)
    end
  end

  scope :index, :show, :update, :destroy, with: Scope
end
