module JsonApiController
  module DeactivatableResource
    extend ActiveSupport::Concern

    included do
      before_action only: :destroy do |controller|
        controller.precondition_check
      end
    end

    def destroy
      resource_class.transaction(requires_new: true) do
        Activation.disable_instances!(to_disable)

        to_disable.each do |resource|
          yield resource if block_given?
        end
      end

      deleted_resource_response
    end

    def to_disable
      controlled_resources
    end
  end
end
