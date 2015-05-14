module JSONApiRender
  extend ActiveSupport::Concern

  included do
    ActionController.add_renderer :json_api do |obj, options|
      response_body = JSONApiResponse.format_response_body(obj)
      if options[:generate_response_obj_etag]
        self.headers["ETag"] = JSONApiResponse.response_etag_header(response_body)
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
