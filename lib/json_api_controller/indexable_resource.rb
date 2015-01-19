module JsonApiController
  module IndexableResource
    def index
      if stale?(last_modified: visible_scope.maximum(:updated_at))
        render json_api: serializer.page(params, visible_scope, context)
      end
    end
  end
end
