module JsonApiController
  module ShowableResource
    def show
      if stale?(last_modified: controlled_resource.updated_at)
        render json_api: serializer.resource(params, visible_scope, context)
      end
    end
  end
end
