module RoleControl
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
      def scope_for(action, actor, target: nil, extra_tests: [])
        extra_tests << ownership_test(actor.try(:owner) || actor)
        super(action, actor, target: target, extra_tests: extra_tests)
      end

      def ownership_test(owner)
        arel_table[:owner_id].eq(owner.id).and(arel_table[:owner_type].eq(owner.class))
      end
    end

    def owner?(actor)
      owner == actor || owner == actor.try(:owner)
    end
  end
end
