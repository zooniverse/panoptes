module JSONApiResponses
  extend ActiveSupport::Concern

  def created_resource_response(resources)
    scope = resource_scope(resources)
    response.headers['Last-Modified'] = scope.maximum(:updated_at).httpdate
    json_api_render(:created,
                    create_response(scope),
                    link_header(resources))
  end

  def updated_resource_response
    most_recent = controlled_resources.maximum(:updated_at) ||
                  controlled_resources.max(&:updated_at).updated_at
    response.headers['Last-Modified'] = most_recent.httpdate
    json_api_render(:ok, update_response)
  end

  def method_not_allowed(exception)
    json_api_render(:method_not_allowed, exception)
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

  def unsupported_media_type(exception)
    json_api_render(:unsupported_media_type, exception)
  end

  def unprocessable_entity(exception)
    json_api_render(:unprocessable_entity, exception)
  end

  def precondition_required(exception)
    json_api_render(:precondition_required, exception)
  end

  def precondition_failed(exception)
    json_api_render(:precondition_failed, exception)
  end

  def conflict(exception)
    json_api_render(:conflict, exception)
  end

  def service_unavailable(exception)
    json_api_render(:service_unavailable, exception)
  end

  def forbidden(exception)
    json_api_render(:forbidden, exception)
  end
end
