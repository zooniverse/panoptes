module RoleControl
  module Owner
    extend ActiveSupport::Concern

    module ClassMethods
      def owns(resource, **attributes)
        resource = "owned_#{ resource }".to_sym
        
        unless attributes.has_key?(:class_name)
          attributes[:class_name] = resource.to_s.classify
        end
        
        has_many resource, **attributes, as: :owner
      end
    end

    def owns?(resource)
      resource.owner?(self)
    end
  end
end
