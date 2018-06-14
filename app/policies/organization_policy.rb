class OrganizationPolicy < ApplicationPolicy
  class ReadScope < Scope
    roles_for_private_scope [:owner, :collaborator, :tester, :translator, :scientist, :moderator]

    def public_scope
      scope.where(listed: true)
    end
  end

  class WriteScope < Scope
    roles_for_private_scope [:owner, :collaborator]
  end

  class TranslateScope < Scope
    roles_for_private_scope [:owner, :collaborator, :translator]
  end

  scope :index, :show, :versions, :version, with: ReadScope
  scope :update, :update_links, :destroy, :destroy_links, with: WriteScope
  scope :translate, with: TranslateScope
end
