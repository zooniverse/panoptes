module APIResponseHelpers
  def json_response
    @json ||= JSON.parse(response.body)
  end

  def json_error_message(error_message)
    { errors: [ message: error_message ] }.to_json
  end
end

module APIRequestHelpers
  def set_accept
    request.env['HTTP_ACCEPT'] = "application/vnd.api+json; version=1"
  end

  def set_accept_language
    request.env['HTTP_ACCEPT_LANGUAGE'] = 'en, zh;q=0.9, zh-tw;q=0.8, fr-fr;q=0.6'
  end

  def set_patch_content_type
    request.headers["Content-Type"] = "application/json-patch"
  end

  def stub_token(scopes: [], user_id: nil)
    allow(controller).to receive(:doorkeeper_token) { double( accessible?: true,
                                                              scopes: scopes,
                                                              acceptable?: true,
                                                              resource_owner_id: user_id ) }
  end

  def stub_token_with_scopes(*scopes)
    stub_token(scopes: scopes)
  end

  def stub_token_with_user(user)
    stub_token(user_id: user.id)
  end

  def default_request(scopes: ["public"], user_id: nil)
    set_accept
    set_accept_language
    stub_token(scopes: scopes, user_id: user_id)
  end
end

module CellectHelpers
  def stub_cellect_connection
    @cellect_connection = instance_double(Cellect::Client::Connection)
    allow(@cellect_connection).to receive(:add_seen)
    allow(@cellect_connection).to receive(:load_user)
    allow(@cellect_connection).to receive(:get_subjects)
    allow(Cellect::Client).to receive(:choose_host).and_return("example.com")
    allow(Cellect::Client).to receive(:connection).and_return(@cellect_connection)
  end

  def stubbed_cellect_connection
    @cellect_connection
  end
end
