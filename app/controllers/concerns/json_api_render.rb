module JSONApiRender
  extend ActiveSupport::Concern

  included do
    ActionController.add_renderer :json_api do |obj, options|
      self.content_type ||= Mime::Type.lookup("application/vnd.api+json; version=1")
      self.response_body = JSONApiResponse.format_response_body(obj)
    end
  end

  private

    class JSONApiResponse

      def self.format_response_body(obj)
        response = obj.is_a?(Exception) ? { errors: [ message: obj.message ] } : obj
        response.to_json
      end
    end
end
