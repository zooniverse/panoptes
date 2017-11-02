module RoleControl
  class AccessDenied < StandardError; end

  module RoledController
    extend ActiveSupport::Concern

    included do
      before_action :check_controller_resources, except: :create
    end

    def check_controller_resources
      unless resources_exist?
        raise_no_resources_error
        rejected_message = rejected_message(resource_ids)
        raise RoleControl::AccessDenied, rejected_message
      end
    end

    def resources_exist?
      resource_ids.blank? ? true : controlled_resources.exists?
    end

    def controlled_resources
      @controlled_resources ||= find_controlled_resources(resource_class, resource_ids)
    end

    def find_controlled_resources(controlled_class, controlled_ids)
       api_user.do(controlled_scope)
       .to(controlled_class, scope_context, add_active_scope: add_active_resources_scope)
       .with_ids(controlled_ids)
       .scope
    end

    def controlled_scope
      action_name.to_sym
    end

    def raise_no_resources_error
      raise RoleControl::AccessDenied, send(:rejected_message)
    end

    def rejected_message
      if resource_ids.is_a?(Array)
        "Could not find #{resource_sym} with ids='#{resource_ids.join(',')}'"
    def rejected_message(denied_resource_ids)
      if denied_resource_ids.is_a?(Array)
        "Could not find #{resource_sym} with ids='#{denied_resource_ids.join(',')}'"
      else
        "Could not find #{resource_name} with id='#{denied_resource_ids}'"
      end
    end

    def resource_ids
      @resource_ids ||= _resource_ids
      return @resource_ids if @resource_ids

      ids = resource_ids_from_params
      @resource_ids = if ids.length < 2
                        ids.first
                      else
                        ids
                      end
    end

    def _resource_ids
      # ids = if respond_to?(:resource_name) && params.has_key?("#{ resource_name }_id")
      #         params["#{ resource_name }_id"]
      #       elsif params.has_key?(:id)
      #         params[:id]
      #       else
      #         ''
      #       end.split(',')

      ids = if params.has_key?(:id)
              params[:id]
            else
              ''
            end.split(',')

      ids.length < 2 ? ids.first : ids
    def resource_ids_from_params
      if respond_to?(:resource_name) && params.has_key?("#{ resource_name }_id")
        params["#{ resource_name }_id"]
      elsif params.has_key?(:id)
        params[:id]
      else
        ''
      end.split(',')
    end

    def scope_context
      {}
    end

    def add_active_resources_scope
      true
    end
  end
end
