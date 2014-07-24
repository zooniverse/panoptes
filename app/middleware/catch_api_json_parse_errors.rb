class CatchApiJsonParseErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::ParamsParser::ParseError => error
      if json_api_call?(env)
        return error_response(error)
      else
        raise error
      end
    end
  end

  private

  def json_api_call?(env)
    json_content_type = !!env['CONTENT_TYPE'].match(/application\/json/)
    json_api_request  = !!env['HTTP_ACCEPT'].match(/application\/vnd\.api\+json; version=\d/)
    json_api_request && json_content_type
  end

  def json_content_header
    { "Content-Type" => "application/json" }
  end

  def error_response(error)
    error_message = "There was a problem in the JSON you submitted: #{error.message}"
    error_response_body = { errors: [ message: error_message ] }.to_json
    [ 400, json_content_header, error_response_body ]
  end
end
