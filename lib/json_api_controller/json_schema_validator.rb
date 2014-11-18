module JsonApiController
  module JsonSchemaValidator
    extend ActiveSupport::Concern

    module ClassMethods
      def allowed_params(action, &block)
        @action_params[action] = if block_given?
                                   JsonSchema.build(&block)
                                 else
                                   path = schema_path(action)
                                   JsonSchema.build_eval(File.read(path))
                                 end
      end

      def action_params
        @action_params
      end

      private
      
      def schema_path(action)
        Rails.root.join("app/schemas/#{ resource_name }_#{ action }_schema.rb")
      end
    end

    protected

    def params_for(action=action_name.to_sym)
      ps = params[resource_sym]
      self.class.action_params[action].validate!(ps)
      ps
    end
    
    alias_method :create_params, :params_for
    alias_method :update_params, :params_for
  end
end
