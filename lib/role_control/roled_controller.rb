module RoleControl
  class AccessDenied < StandardError; end
  
  module RoledController
    extend ActiveSupport::Concern

    included do
      attr_accessor :controlled_resources
    end

    DEFAULT_ACCESS_CONTROL_ACTIONS = %i(update show index destroy update_links destory_links)

    module ClassMethods
      def setup_access_control!(*actions, &block)
        actions = DEFAULT_ACCESS_CONTROL_ACTIONS if actions.blank?
        actions.each do |action|
          action, scope_action = action
          method_name = :"access_control_for_#{ action }"

          define_method method_name do
            resource_ids = send(:resource_ids)
            
            resource_scope = send(:api_user)
                             .do(scope_action || action, &block)
                             .to(send(:resource_class), scope_context)
                             .with_ids(resource_ids)

            send(:controlled_resources=, resource_scope.scope)
            
            unless send(:controlled_resources).exists?
              raise RoleControl::AccessDenied, send(:rejected_message)
            end
          end
          
          before_action method_name, only: [action]
        end
      end
    end

    protected

    def rejected_message
      if resource_ids.length == 1
        "Could not find #{resource_name} with id='#{resource_ids.first}'"
      else
        "Could not find #{resource_sym} with ids='#{resource_ids.join(',')}'"
      end
    end

    def resource_ids
      @resource_ids =
        if respond_to?(:resource_name) && params.has_key?("#{ resource_name }_id")
          params["#{ resource_name }_id"]
        elsif params.has_key?(:id)
          params[:id]
        else
          ''
        end.split(',')
    end
  end
end
