module RoleControl
  class AccessDenied < StandardError; end

  module RoledController
    extend ActiveSupport::Concern

    included do
      before_action :check_controller_resources, except: :create
    end
    
    def check_controller_resources
      unless resources_exist?
        raise RoleControl::AccessDenied, send(:rejected_message)
      end
    end
    
    def resources_exist?
      resource_ids.blank? ? true : controlled_resources.exists?(id: resource_ids)
    end

    def controlled_resources
      @controlled_resources ||= api_user.do(action_name.to_sym)
                              .to(resource_class, scope_context)
                              .with_ids(resource_ids)
                              .scope
      #p @controlled_resources.to_sql
      @controlled_resources
    end

    def rejected_message
      if resource_ids.is_a?(Array)
        "Could not find #{resource_sym} with ids='#{resource_ids.join(',')}'"
      else
        "Could not find #{resource_name} with id='#{resource_ids}'"
      end
    end

    def resource_ids
      @resource_ids = _resource_ids
    end

    def _resource_ids
      ids = if respond_to?(:resource_name) && params.has_key?("#{ resource_name }_id")
              params["#{ resource_name }_id"]
            elsif params.has_key?(:id)
              params[:id]
            else
              ''
            end.split(',')

      ids.length < 2 ? ids.first : ids
    end

    def scope_context
      {}
    end
  end
end
