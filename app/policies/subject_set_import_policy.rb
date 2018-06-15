class SubjectSetImportPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      return scope.none unless user.logged_in?

      parent_scope = SubjectSet.scope_for(:update, user)
      scope.where(subject_set_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, with: Scope
end
