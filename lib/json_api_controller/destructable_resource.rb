module JsonApiController
  module DestructableResource
    extend ActiveSupport::Concern

    included do
      before_action only: :destroy do |controller|
        controller.precondition_check
      end
    end

    def destroy
      binding.pry unless controller_name.classify == controlled_resource.class.name
      controlled_resources.destroy_all
      deleted_resource_response
    end
  end
end
