module ControlControl
  module Resource
    def self.included(mod)
      mod.extend(ClassMethods)
    end
    
    module ClassMethods
      def can_create?(actor)
        true
      end

      def multi_read_scope(actor)
        all
      end
    end

    def can_act?(actor)
      is_resource_owner?(actor)
    end

    alias_method :can_read?, :can_act?
    alias_method :can_write?, :can_act?
    alias_method :can_delete?, :can_act?

    def is_resource_owner?(actor)
      actor.owns?(self)
    end
  end
end
