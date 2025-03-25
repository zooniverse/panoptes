module JsonApiController
  module ShowableResource
    def show
      # convert the query scope to an array of active record objects (vs an ActiveRecord::Relation scope)
      # to ensure we generate the cache key based on the underlying Active Record objects
      # and thus have a stable cache key
      # https://api.rubyonrails.org/v5.0/classes/ActiveRecord/Integration.html#method-i-cache_key
      # as opposed to the ActiveRecord::Relation which depends on the query sql
      # https://api.rubyonrails.org/v5.0/classes/ActiveRecord/Relation.html#method-i-cache_key
      headers['ETag'] = gen_etag(controlled_resources.to_a)
      render json_api: serializer.resource(params, controlled_resources, context),
             add_http_cache: params[:http_cache]
    end
  end
end
