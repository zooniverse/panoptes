module ResponseHelpers
  def json_response
    @json ||= JSON.parse(response.body)
  end
end

module RequestHelpers
  def set_accept
    request.headers["Accept"] = "application/vnd.api+json; version=1"
  end

  def set_patch_content_type
    request.headers["Content-Type"] = "application/json-patch"
  end

  def stub_token
    allow(controller).to receive(:doorkeeper_token) { doube accessible?: true }
  end

  def stub_token_with_scopes(*scopes)
    allow(controller).to receive(:dookeeper_token) { doube accessible?: true, scopes: scopes }
  end

  def default_request
    set_accept
    stub_token
  end
end
