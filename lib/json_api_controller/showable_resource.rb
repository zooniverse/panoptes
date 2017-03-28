module JsonApiController
  module ShowableResource
    def show
      headers['ETag'] = gen_etag(controlled_resources)
      render json_api: serializer.resource(params, controlled_resources, context),
             add_http_cache: params[:http_cache]
    end
  end
end
