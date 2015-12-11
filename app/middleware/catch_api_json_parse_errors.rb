class CatchApiJsonParseErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::ParamsParser::ParseError, JSON::ParserError => e
      if json_api_call?(env)
        return error.respond(e)
      else
        raise e
      end
    end
  end

  private

  def error
    @error ||= ErrorResponse.new(400, error_message)
  end

  def error_message
    "There was a problem in the JSON you submitted"
  end

  def json_api_call?(env)
    json_content_type = !!env['CONTENT_TYPE'].match(/application\/json/)
    json_api_request  = !!env['HTTP_ACCEPT'].match(/application\/vnd\.api\+json; version=\d/)
    json_api_request && json_content_type
  end
end
