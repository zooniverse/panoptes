module JsonApiController
  module IndexableResource
    def index
      if stale?(visible_scope)
        render json_api: serializer.page(params, visible_scope, context)
      end
    end
  end
end
