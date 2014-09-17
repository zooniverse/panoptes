module JsonApiController
  module IndexableResource
    def index
      render json_api: serializer.page(params, visible_scope)
    end
  end
end
