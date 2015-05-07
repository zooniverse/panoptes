module JsonApiController
  module ShowableResource
    def show
      response_obj = serializer.resource(params, controlled_resources, context)
      headers['ETag'] = gen_etag(response_obj)
      render json_api: response_obj
    end
  end
end
