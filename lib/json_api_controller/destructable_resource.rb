module JsonApiController
  module DestructableResource
    extend ActiveSupport::Concern

    included do
      before_action only: :destroy do |controller|
        controller.precondition_check
      end
    end

    def destroy
      controlled_resources.destroy_all
      deleted_resource_response
    end
  end
end
