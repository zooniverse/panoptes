class RejectPatchRequests
  def initialize(app)
    @app = app
  end

  def call(env)
    return error.respond if env['REQUEST_METHOD'] == 'PATCH'
    @app.call(env)
  end

  private

  def error
    @error ||= ErrorResponse.new(501, "PATCH Requests are not currently supported")
  end
end
