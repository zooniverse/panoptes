module ControlControl
  module Ownable
    extend ActiveSupport::Concern
    
    included do 
      can :show, :owner?
      can :update, :owner?
      can :destroy, :owner?

      belongs_to :owner, polymorphic: true
      validates_presence_of :owner
    end

    def owner?(actor)
      owner == actor || owner == actor.try(:owner)
    end
  end
end
