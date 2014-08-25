module RoleControl
  module RoledController
    extend ActiveSupport::Concern

    module ClassMethods
      def access_control_action(action, resource_class: nil, actor_method: :api_user, &block)
        if !!resource_class && !method_defined?(:resource_class)
          define_resource_class(resource_class)
        end

        before_action only: [action] do |controller|
          resource = controller.send(:controlled_resource)
          act_as = controller.send(:owner_from_params)
          
          actor(block || actor_method).do(action)
            .to(resource)
            .as(act_as, allow_nil: false)
            .allowed?
        end
      end

      def access_control_for(*actions, resource_class: nil)
        actions.each do |action|
          access_control_action(action, resource_class: resource_class)
        end
      end

      protected 

      def define_resource_class(klass)
        define_method :resource_class do
          klass
        end
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

    def controlled_resource
      @controlled_resource ||= if params.has_key?(:id)
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
