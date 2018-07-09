class ProjectPolicy < ApplicationPolicy
  class ReadScope < Scope
    roles_for_private_scope %i(owner collaborator tester translator scientist moderator)

    def public_scope
      scope.where(private: false)
    end
  end

  class WriteScope < Scope
    roles_for_private_scope %i(owner collaborator)
  end

  class TranslateScope < Scope
    roles_for_private_scope %i(owner collaborator translator)
  end

  scope :index, :show, :versions, :version, with: ReadScope
  scope :update, :update_links, :destroy, :destroy_links,
        :create_classifications_export,
        :create_subjects_export,
        :create_workflows_export,
        :create_workflow_contents_export,
        :retire_subjects, with: WriteScope
  scope :translate, with: TranslateScope

  def linkable_subject_sets
    # We return all visible sets here, but those that don't belong to this
    # resource will get cloned when linked.
    policy_for(SubjectSet).scope_for(:show)
  end

  def linkable_workflows
    # We return all visible workflows here, but those that don't belong to this
    # resource will get cloned when linked.
    policy_for(Workflow).scope_for(:show)
  end

  def linkable_user_groups
  end
end
