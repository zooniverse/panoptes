module JsonApiController
  module DestructableResource
    extend ActiveSupport::Concern

    class IncorrectClass < StandardError; end

    included do
      before_action :precondition_check, only: :destroy
      before_action :check_destroy_class_matches_controller, only: :destroy
    end

    def destroy
      controlled_resources.destroy_all
      deleted_resource_response
    end

    private

    def check_destroy_class_matches_controller
      resource_class_name = controlled_resource.class.name
      if controller_name.classify != resource_class_name
        msg = "Attempting to delete the wrong resource type - #{resource_class_name}"
        raise IncorrectClass.new(msg)
      end
    end
  end
end
