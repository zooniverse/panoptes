module RoleControl
  module RoledController
    extend ActiveSupport::Concern

    module ClassMethods
      def access_control_action(action, resource_class: nil, actor_method: :api_user, &block)
        if !!resource_class && !method_defined?(:resource_class)
          define_resource_class(resource_class)
        end

        old_action = alias_action(action) 
        define_method action do
          actor(block || actor_method).do(action)
            .to(resource)
            .as(owner_from_params, allow_nil: false)
            .call(no_args: true, &method(old_action))
          end
      end

      def default_access_control(resource_class: nil, except: [])
        ([:show, :create, :update, :destroy] - except).each do |action|
          access_control_action(action, resource_class: resource_class)
        end
      end

      protected 

      def define_resource_class(klass)
        define_method :resource_class do
          klass
        end
      end

      def alias_action(action)
        old_action_name = "_#{ action }_old".to_sym
        alias_method(old_action_name, action)
        old_action_name 
      end

    end

    protected

    def actor(actor_method)
      @actor ||= if actor_method.is_a?(Symbol)
                   send(actor_method)
                 else
                   actor_method.call(request)
                 end
    end

    def resource
      @resource ||= if params.has_key?(:id)
                      resource_class.find(params[:id])
                    else
                      resource_class
                    end
    end

    def owner_from_params
      @owner ||= OwnerName.where(name: params[:owner]).first.try(:resource)
    end

    def visible_scope(actor)
      @scope ||= resource_class.scope_for(:show, actor)
    end
  end
end
