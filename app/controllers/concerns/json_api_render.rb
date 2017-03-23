module JSONApiRender
  extend ActiveSupport::Concern

  CACHEABLE_RESOURCES = { subjects: "public max-age: 60" }.freeze

  included do
    ActionController.add_renderer :json_api do |obj, options|
      response_body = JSONApiResponse.format_response_body(obj)
      if options[:generate_response_obj_etag]
        self.headers["ETag"] = JSONApiResponse.response_etag_header(response_body)
      end
      resource_cache_directive = CACHEABLE_RESOURCES[resource_sym]
      if resource_cache_directive && options[:add_http_cache] == "true"

        #TODO: move this to some infelctor or render options
        parent_class = resource_class.parent_class
        parent_resource_ids = controlled_resources.map do |cr|
          cr.send resource_class.parent_foreign_key
        end

        contains_private_data = parent_class
          .private_scope
          .where(id: parent_resource_ids)
          .exists?

        if !contains_private_data
          self.headers["Cache-Control"] = resource_cache_directive
        end
      end
      self.content_type ||= Mime::Type.lookup("application/vnd.api+json; version=1")
      self.response_body = response_body
    end

  end

  def json_api_render(status, content, location=nil)
    render status: status, json_api: content, location: location
  end

  private

  class JSONApiResponse

    def self.format_response_body(obj)
      response = obj.is_a?(Exception) ? { errors: [ message: obj.message ] } : obj
      response.to_json
    end

    def self.response_etag_header(obj)
      %("#{Digest::MD5.hexdigest(obj)}")
    end
  end
end
