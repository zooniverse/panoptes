module JsonApiController
  module JsonSchemaValidator
    extend ActiveSupport::Concern

    included do
      @action_params = Hash.new
      (@actions & %i(update create)).each do |action|
        @action_params[action] = schema_class(action).new
      end
    end

    module ClassMethods
      def action_params
        @action_params
      end

      private

      def schema_class(action)
        "#{ resource_name }_#{ action }_schema".camelize.constantize
      end
    end

    protected

    def params_for(action=action_name.to_sym)
      ps = params.require(resource_sym).permit!
      self.class.action_params[action].validate!(ps)
      ps
    end

    alias_method :create_params, :params_for
    alias_method :update_params, :params_for
  end
end
