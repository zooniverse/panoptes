module ControlControl
  module Adminable
    extend ActiveSupport::Concern

    included do
      can :show, :admin?
      can :update, :admin?
      can :destroy, :admin?
    end

    def admin?(actor)
      actor.is_admin?
    end
  end
end
