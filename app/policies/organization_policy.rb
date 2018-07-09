class OrganizationPolicy < ApplicationPolicy
  class ReadScope < Scope
    roles_for_private_scope %i(owner collaborator tester translator scientist moderator)

    def public_scope
      scope.where(listed: true)
    end
  end

  class WriteScope < Scope
    roles_for_private_scope %i(owner collaborator)
  end

  class TranslateScope < Scope
    roles_for_private_scope %i(owner collaborator translator)
  end

  scope :index, :show, :versions, :version, with: ReadScope
  scope :update, :update_links, :destroy, :destroy_links, with: WriteScope
  scope :translate, with: TranslateScope

  def linkable_projects
    # TODO: Is this really right? This lets me stick any
    # project in my organization. What if they don't want to?
    policy_for(Project).scope_for(:show)
  end
end
