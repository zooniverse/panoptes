module ControlControl
  module Owner
    extend ActiveSupport::Concern

    module ClassMethods
      def owns(resource, **attributes)
        has_many resource, **attributes, as: :owner
      end
    end

    def owns?(resource)
      resource.owner?(self)
    end
  end
end
