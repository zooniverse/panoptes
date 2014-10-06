class ContentTypeFilter
  attr_reader :acceptable_content_types
  attr_reader :http_method_overrides

  def initialize(*content_types, http_method_overrides)
    @acceptable_content_types, @http_method_overrides = content_types, http_method_overrides
  end

  def before(controller)
    setup_request_variables(controller)
    return true if empty_request?
    unless acceptable_content?
      raise Api::UnsupportedMediaType.new(unsupported_media_type_message)
    end
  end

  private

  def setup_request_variables(controller)
    @request = controller.request
    @request_content_type = @request.media_type
    @request_method = @request.request_method
  end

  def empty_request?
    @request.get? || @request.delete? || @request.head? || @request.options?
  end

  def allowed_override_method?
    @http_method_overrides.include?(@request_method)
  end

  def overriden_content_types
    [ @http_method_overrides[@request_method] ].compact
  end

  def allowed_content_types
     if allowed_override_method?
       overriden_content_types
     else
       acceptable_content_types
     end
  end

  def acceptable_content?
    allowed_content_types.include?(@request_content_type)
  end

  def unsupported_media_type_message
    types = acceptable_content_types.join(" or ")
    "Only requests with Content-Type: #{ types } are allowed"
  end
end
