class OrganizationPolicy < ApplicationPolicy
  class ReadScope < Scope
    roles_for_private_scope [:owner, :collaborator, :tester, :translator, :scientist, :moderator]

    def public_scope
      scope.where(listed: true)
    end

    def private_scope
      scope.where(listed: false)
    end
  end

  class WriteScope < Scope
    roles_for_private_scope [:owner, :collaborator]

    def public_scope
      scope.none
    end

    def private_scope
      scope.where(listed: false)
    end
  end

  class TranslateScope < Scope
    roles_for_private_scope [:owner, :collaborator, :translator]

    def public_scope
      scope.none
    end

    def private_scope
      scope.where(listed: false)
    end
  end

  scope :index, :show, :versions, :version, with: ReadScope
  scope :update, :update_links, :destroy, :destroy_links, with: WriteScope
  scope :translate, with: TranslateScope
end
