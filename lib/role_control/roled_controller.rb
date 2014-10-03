module RoleControl
  module RoledController
    extend ActiveSupport::Concern

    module ClassMethods
      def access_control_action(controller_action, test_action, resource_class: nil, actor_method: :api_user, &block)
        before_action only: [controller_action] do |controller|
          resource = controller.send(:controlled_resource)
          act_as = controller.send(:owner_from_params)
          
          actor(block || actor_method).do(test_action)
            .to(resource)
            .as(act_as, allow_nil: false)
            .allowed?
        end
      end

      def access_control_for(*actions, resource_class: nil)
        actions.each do |(controller_action, test_action)|
          test_action ||= controller_action
          access_control_action(controller_action, test_action, resource_class: resource_class)
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
      @owner ||= if params[:owner]
                   OwnerName.where(name: params[:owner]).first.try(:resource)
                 elsif params[resource_sym].try(:has_key, :owner)
                   owner_from_link_params
                 else
                   nil
                 end
    end

    def visible_scope(actor)
      @scope ||= resource_class.scope_for(:show, actor)
    end

    protected

    def owner_from_links_params
      id, type = params[resource_name.pluralize.to_sym][:owner]
        .values_at(:id, :type)
      type = type.camelize.constantize
      
      unless type < RoleControl::Owner
        raise StandardError.new('type is not owner')
      end
      
      type.find(id)
    end
  end
end
