module ControlControl
  module ActAs
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def can_as(action, filter=nil, &block)
        action = "#{ action }_as"
        can(action, filter, &block)
      end
    end
  end
end
