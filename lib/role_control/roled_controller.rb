module RoleControl
  class AccessDenied < StandardError; end

  module RoledController
    extend ActiveSupport::Concern

    included do
      before_action :check_controller_resources, except: :create
    end

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
      raise RoleControl::AccessDenied, rejected_message(resource_ids)
    end

    def rejected_message(denied_resource_ids)
      msg_prefix = "Could not find #{resource_name} with"
      if denied_resource_ids.is_a?(Array)
        "#{msg_prefix} ids='#{denied_resource_ids.join(',')}'"
      else
        "#{msg_prefix} id='#{denied_resource_ids}'"
      end
    end

    def resource_ids
      return @resource_ids if @resource_ids
      ids = _resource_ids.split(',')
      @resource_ids = if ids.length < 2
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
