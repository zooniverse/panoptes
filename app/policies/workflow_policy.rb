class WorkflowPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(action)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :update, :destroy, :update_links, :destroy_links,
        :translate, :versions, :version, :retire_subjects, :create_classifications_export,
        with: Scope

  def linkable_subject_sets
    # Note: Any set that is not part of the same project gets duplicated in the
    # controller, not associated directly.
    policy_for(SubjectSet).scope_for(:show)
  end

  def linkable_retired_subjects
    policy_for(Subject).scope_for(:show)
  end

  def linkable_tutorials
    policy_for(Tutorial).scope_for(:update)
  end

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end

  def linkable_tutorial_subjects
    policy_for(Subject).scope_for(:show)
  end
end
