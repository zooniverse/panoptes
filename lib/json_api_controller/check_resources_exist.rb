module JsonApiController
  class AccessDenied < StandardError; end

  # Depends on the following methods to be defined wherever this is mixed in:
  #
  # * resource_ids
  # * resource_name
  # * policy_scope
  #
  # These are normally provided by JsonApiController
  module CheckResourcesExist
    extend ActiveSupport::Concern

    included do
      before_action :check_controller_resources, except: [:create]
    end

    private

    def check_controller_resources
      raise_no_resources_error unless resources_exist?
    end

    def resources_exist?
      resource_ids.blank? ? true : policy_scope.exists?
    end

    def raise_no_resources_error
      raise JsonApiController::AccessDenied, no_resources_error_message
    end

    def no_resources_error_message
      "Could not find #{resource_name} with #{no_resources_message_ids}"
    end

    def no_resources_message_ids
      if resource_ids.is_a?(Array)
        "ids='#{resource_ids.join(',')}'"
      else
        "id='#{resource_ids}'"
      end
    end
  end
end
