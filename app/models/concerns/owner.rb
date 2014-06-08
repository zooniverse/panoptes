module Owner
  extend ActiveSupport::Concern

  module ClassMethods
    def owns(*owned)
      owned.each do |properties_type|
        if properties_type.length == 2
          properties_type, attributes = properties_type
          attributes[:as] = :owner
          has_many properties_type, **attributes
        else
          has_many properties_type, as: :owner
        end
      end
    end
  end
end
