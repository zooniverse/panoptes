module JSONApiRender
  extend ActiveSupport::Concern

  included do
    ActionController.add_renderer :json_api do |obj, options|
      json = obj.to_json
      self.content_type ||= Mime::Type.lookup("application/vnd.api+json; version=1")
      self.response_body = json
    end
  end
end
