module JsonApiController
  module IndexableResource
    def index
      headers['ETag'] = gen_etag(controlled_resources)
      render json_api: serializer.page(params, controlled_resources, context)
    end
  end
end
