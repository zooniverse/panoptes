module RoleControl
  class AccessDenied < StandardError; end
  
  module RoledController
    extend ActiveSupport::Concern

    module ClassMethods
      def access_control_action(controller_action, test_action, actor_method: :api_user, &block)
        method_name = :"access_control_for_#{ controller_action }"

        define_method method_name do
          resource = send(:controlled_resource)
          act_as = send(:owner_from_params)

          actor(block || actor_method).do(test_action)
            .to(resource)
            .as(act_as, allow_nil: false)
            .allowed?
        end
        
        before_action method_name, only: [controller_action]
      end

      def access_control_for(*actions)
        actions.each do |(controller_action, test_action)|
          test_action ||= controller_action
          access_control_action(controller_action, test_action)
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
      @controlled_resource ||= 
        if respond_to?(:resource_name) && params.has_key?("#{ resource_name }_id")
          resource_class.find(params["#{ resource_name }_id"])
        elsif params.has_key?(:id)
          resource_class.find(params[:id])
        else
          resource_class
        end
    end

    def owner_from_params
      @owner ||=
        if params[:owner]
          OwnerName.where(name: params[:owner]).first.try(:resource)
        else
          owner_from_links_params
        end
    end

    def visible_scope(actor)
      @scope ||= resource_class.scope_for(:show, actor)
    end

    protected

    def owner_from_links_params
      id, type = params.fetch(resource_sym, {})
                 .fetch(:links, {})
                 .fetch(:owner, {})
                 .values_at(:id, :type)
      if id && type
        type = type.singularize.camelize.constantize
        
        unless type < RoleControl::Owner
          raise StandardError.new('type is not owner')
        end
        
        type.find(id)
      end
    end
  end
end
