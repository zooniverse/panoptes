module JsonApiController
  module IndexableResource
    def index
      fresh_when last_modified: visible_scope.maximum(:updated_at)
      render json_api: serializer.page(params, visible_scope, context)
    end
  end
end
