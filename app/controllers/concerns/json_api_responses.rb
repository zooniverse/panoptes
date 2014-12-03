module JSONApiResponses
  extend ActiveSupport::Concern

  def created_resource_response(resource)
    json_api_render(:created,
                    create_response(resource),
                    link_header(resource))
  end

  def updated_resource_response(resource)
    json_api_render(:ok,
                    update_response(resource),
                    link_header(resource))
  end

  def deleted_resource_response
    json_api_render(:no_content, {})
  end

  def not_authenticated(exception)
    json_api_render(:unauthorized, exception)
  end

  def not_authorized(exception)
    json_api_render(:forbidden, exception)
  end

  def not_found(exception)
    json_api_render(:not_found, exception)
  end

  def invalid_record(exception)
    json_api_render(:bad_request, exception)
  end

  def bad_query(exception)
    message = StandardError.new(exception.message.match(/ERROR:(\s*)(.*):/)[-1])
    json_api_render(:bad_request, message)
  end

  def unsupported_media_type(exception)
    json_api_render(:unsupported_media_type, exception)
  end

  def unprocessable_entity(exception)
    json_api_render(:unprocessable_entity, exception)
  end
end
