class SubjectSetImportPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      return scope.none unless user.logged_in?

      parent_scope = policy_for(SubjectSet).scope_for(:update)
      scope.where(subject_set_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, with: Scope
end
