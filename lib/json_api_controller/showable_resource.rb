module JsonApiController
  module ShowableResource
    def show
      render json_api: serializer.resource(params, visible_scope, context)
    end
  end
end
