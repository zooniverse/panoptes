module JSONApiRender
  extend ActiveSupport::Concern

  included do
    ActionController.add_renderer :json_api do |obj, options|
      self.content_type ||= Mime::Type.lookup("application/vnd.api+json; version=1")
      self.response_body = JSONApiResponse.format_response_body(obj, options)
    end
  end

  private

    class JSONApiResponse

      def self.format_response_body(obj, options)
        error_reponse = options[:status].to_s.match(/^[4|5]\d{2}$/)
        response = error_reponse ? { errors: [ message: obj ] } : obj
        response.to_json
      end
    end
end
