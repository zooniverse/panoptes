class ContentTypeFilter
  attr_reader :acceptable_content
  attr_reader :overrides

  def initialize(*content_types, overrides)
    @acceptable_content, @overrides = content_types, overrides
  end

  def before(controller)
    # If the request is a type that doesn't have a body don't check media type
    return true if empty_request?(controller.request)

    content_type = controller.request.media_type
    method = controller.request.request_method

    if overridden_method?(method)
      accepted = matches?(content_type, method)
    else
      accepted = matches?(content_type)
    end

    unless accepted
      raise Api::UnsupportedMediaType.new(
        "Only requests with Content-Type: application/json are allowed"
      )
    end
  end

  private

  def empty_request?(request)
    request.get? || request.delete? || request.head? || request.options?
  end

  def overridden_method?(method)
    overrides.include?(method)
  end

  def matches?(content_type, method=nil)
    acceptable = method.nil? ? acceptable_content : overrides[method]
    acceptable.include?(content_type)
  end
end
