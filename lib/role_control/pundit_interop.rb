module RoleControl
  module PunditInterop
    extend ActiveSupport::Concern

    module ClassMethods
      def scope_for(action, api_user, opts={})
        Pundit.policy!(api_user, self).scope_for(action)
      end
    end
  end
end
