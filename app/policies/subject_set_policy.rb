class SubjectSetPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = Project.scope_for(action, user)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :update, :destroy, :update_links, :destroy_links, with: Scope
end
