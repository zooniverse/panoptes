class SetMemberSubjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(SubjectSet).scope_for(action)
      scope.where(subject_set_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :update, :destroy, :update_links, :destroy_links, with: Scope

  def linkable_subjects
    policy_for(Subject).scope_for(:show)
  end

  def linkable_subject_sets
    policy_for(SubjectSet).scope_for(:update)
  end

  def linkable_retired_workflows
    policy_for(Workflow).scope_for(:update)
  end
end
