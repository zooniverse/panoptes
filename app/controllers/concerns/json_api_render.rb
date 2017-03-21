module JSONApiRender
  extend ActiveSupport::Concern

  included do
    ActionController.add_renderer :json_api do |obj, options|
      response_body = JSONApiResponse.format_response_body(obj)
      if options[:generate_response_obj_etag]
        self.headers["ETag"] = JSONApiResponse.response_etag_header(response_body)
      end
      if options[:add_http_cache] == "true"
        if all_public_resources?

          # def public_resources?
          #   binding.pry
          #   controlled_class, controlled_attribute = if resource_class.respond_to?(:parent_class)
          #     parent_relation = resource_class.reflect_on_association(resource_class.parent_relation)
          #     [ resource_class.parent_class, parent_relation.foreign_key ]
          #   else
          #     [ resource_class, :id ]
          #   end
          #   # MOVE THIS TO SOME SET EQUALITY OPERATOR INSTEAD OF COMPARING request_params
          #   # OF ID's before a limit is applied
          #   # this may not even be feasible
          #   # if not then we'll have to cache public routes only
          #   controlled_resource_ids = controlled_resources.pluck(controlled_attribute)
          #   controlled_class.public_scope.where(id: controlled_resource_ids).pluck(:id)
          # end

          self.headers["Cache-Control"] = ""
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
