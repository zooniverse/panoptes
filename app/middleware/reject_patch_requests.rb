class RejectPatchRequests
  def initialize(app)
    @app = app
  end

  def call(env)
    return error.respond if api_route?(env) && uses_patch?(env)
    @app.call(env)
  end

  private

  def uses_patch?(env)
    env['REQUEST_METHOD'] == 'PATCH'
  end

  def api_route?(env)
    env['PATH_INFO'] =~ /api/
  end

  def error
    @error ||= ErrorResponse.new(501, "PATCH Requests are not currently supported")
  end
end
