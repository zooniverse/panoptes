module RoleControl
  class AccessDenied < StandardError; end

  module RoledController
    extend ActiveSupport::Concern

    included do
      before_action :check_controller_resources, except: :create
    end

    private

    def check_controller_resources
      raise_no_resources_error unless resources_exist?
    end

    def resources_exist?
      resource_ids.blank? ? true : controlled_resources.exists?
    end

    def controlled_resources
      @controlled_resources ||= find_controlled_resources(resource_class, resource_ids)
    end

    def controlled_resource
      @controlled_resource ||= controlled_resources.first
    end

    def find_controlled_resources(controlled_class, controlled_ids, action=controlled_scope)
       api_user.do(action)
       .to(controlled_class, scope_context, add_active_scope: add_active_resources_scope)
       .with_ids(controlled_ids)
       .scope
    end

    def controlled_scope
      action_name.to_sym
    end

    def raise_no_resources_error
      raise RoleControl::AccessDenied, no_resources_error_message
    end

    def no_resources_error_message(resource=resource_name)
      msg_prefix = "Could not find #{resource} with"
      if resource_ids.is_a?(Array)
        "#{msg_prefix} ids='#{resource_ids.join(',')}'"
      else
        "#{msg_prefix} id='#{resource_ids}'"
      end
    end

    def resource_ids
      @resource_ids ||= array_id_params(_resource_ids)
    end

    def array_id_params(string_id_params)
      ids = string_id_params.split(',')
      if ids.length < 2
        ids.first
      else
        ids
      end
    end

    def _resource_ids
      if params.has_key?(:id)
        params[:id]
      else
        ''
      end
    end

    def scope_context
      {}
    end

    def add_active_resources_scope
      true
    end
  end
end
