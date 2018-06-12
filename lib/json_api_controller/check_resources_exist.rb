module JsonApiController
  class AccessDenied < StandardError; end

  module CheckResourcesExist
    extend ActiveSupport::Concern

    included do
      before_action :check_controller_resources, except: :create
    end

    private

    def check_controller_resources
      raise_no_resources_error unless policy_object.resources_exist?
    end

    def raise_no_resources_error
      raise JsonApiController::AccessDenied, no_resources_error_message
    end

    def no_resources_error_message
      "Could not find #{resource_name} with #{no_resources_message_ids}"
    end

    def no_resources_message_ids
      if policy_object.resource_ids.is_a?(Array)
        "ids='#{policy_object.resource_ids.join(',')}'"
      else
        "id='#{policy_object.resource_ids}'"
      end
    end
  end
end
