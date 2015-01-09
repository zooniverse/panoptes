module JsonApiController
  module ShowableResource
    def show
      fresh_when last_modified: controlled_resource.updated_at
      render json_api: serializer.resource(params, visible_scope, context)
    end
  end
end
