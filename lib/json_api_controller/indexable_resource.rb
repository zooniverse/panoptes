module JsonApiController
  module IndexableResource
    def index
      render json_api: serializer.page(params, controlled_resources, context),
             generate_response_obj_etag: true,
             add_http_cache: params[:http_cache]
    end
  end
end
