module ControlControl
  module Owner
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def owner_of(resource, **attributes)
        has_many resource, **attributes, as: :owner
      end
    end

    def owns?(resource)
      resource.owner?(self)
    end
  end
end
