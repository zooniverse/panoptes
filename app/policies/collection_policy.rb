class CollectionPolicy < ApplicationPolicy
  class ReadScope < Scope
    roles_for_private_scope %i(owner collaborator contributor viewer)

    def public_scope
      scope.where(private: false)
    end
  end

  class WriteScope < Scope
    roles_for_private_scope %i(owner collaborator)
  end

  class ContributorScope < Scope
    roles_for_private_scope %i(owner collaborator contributor)
  end

  scope :index, :show, with: ReadScope
  scope :update, :destroy, :destroy_links, with: WriteScope
  scope :update_links, with: ContributorScope
end
