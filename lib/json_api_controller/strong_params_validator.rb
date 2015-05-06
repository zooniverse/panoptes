module JsonApiController
  module StrongParamsValidator
    extend ActiveSupport::Concern

    included do
      @action_params = Hash.new
    end

    module ClassMethods
      def polymorphic
        [ :id, :type ]
      end

      def allowed_params(action, *request_description)
        @action_params[action] = request_description
      end

      def action_params
        @action_params
      end
    end

    protected

    def params_for(action=action_name.to_sym)
      params.require(resource_sym).permit(*self.class.action_params[action])
    end

    alias_method :create_params, :params_for
    alias_method :update_params, :params_for
  end
end
