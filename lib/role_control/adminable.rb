module RoleControl
  module Adminable
    extend ActiveSupport::Concern

    included do
      can :show, :admin?
      can :update, :admin?
      can :destroy, :admin?
    end

    module ClassMethods
      def scope_for(action, actor)
        return all if actor.try(:is_admin?)
        super(action, actor)
      end
    end
    

    def admin?(actor)
      actor.try(:is_admin?)
    end
  end
end
