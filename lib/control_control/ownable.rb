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

    module ClassMethods
      def scope_for(action, actor)
        super(action, actor) & where(owner_id: actor.try(:id),
                                     owner_class: actor.try(:class))
      end
    end

    def owner?(actor)
      owner == actor || owner == actor.try(:owner)
    end
  end
end
