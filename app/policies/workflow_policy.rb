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
    # TODO: Any set that is not part of the same project should get duplicated, not linked.
    # This currently gets done by the controller, and is set up such that this code here
    # must allow it to be in scope for linking. However, this opens the door for bugs to
    # accidentally allow linkage of foreign subject sets. It would be much better if the
    # "same-project" rule was enforced here, and the controller would copy any "not-found"
    # sets into the project.
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
