module JsonApiController
  module ShowableResource
    def show
      if stale?(controlled_resources)
        render json_api: serializer.resource(params, visible_scope, context)
      end
    end
  end
end
