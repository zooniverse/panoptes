module JsonApiController
  module DestructableResource
    extend ActiveSupport::Concern

    included do
      before_action :destroy_precondition_check, only: :destroy
      before_action :check_destroy_class_matches_controller, only: :destroy
    end

    def destroy
      resource_class.transaction(requires_new: true) do
        controlled_resources.each do |resource|
          yield resource if block_given?
          resource.destroy
        end
      end
      deleted_resource_response
    end

    private

    def destroy_precondition_check
      precondition_check
    end

    def check_destroy_class_matches_controller
      resource_class_name = controlled_resource.class.name
      if controller_name.classify != resource_class_name
        msg = "Attempting to delete the wrong resource type - #{resource_class_name}"
        raise ApiErrors::IncorrectClass.new(msg)
      end
    end
  end
end
