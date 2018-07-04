class SetMemberSubjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(SubjectSet).scope_for(action)
      scope.where(subject_set_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :update, :destroy, :update_links, :destroy_links, with: Scope
end
