class ErrorResponse
  def initialize(status, msg)
    @status, @msg = status, msg
  end

  def respond(error=nil)
    error_response_body = { errors: [ message: msg(error) ] }.to_json
    [ @status, json_content_header, error_response_body ]
  end

  private

  def msg(error)
    return @msg unless error
    "#{ @msg }: #{ error.message }"
  end

  def json_content_header
    { "Content-Type" => "application/vnd.api+json" }
  end
end
