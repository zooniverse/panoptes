module JsonApiController
  module IndexableResource
    def index
      response_obj = serializer.page(params, controlled_resources, context)
      headers['ETag'] = gen_etag(response_obj)
      render json_api: response_obj
    end
  end
end
