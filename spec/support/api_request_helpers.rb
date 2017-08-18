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

  def set_preconditions
    allow(controller).to receive(:precondition_check).and_return(true)
  end

  def stub_token(scopes: [], user_id: nil)
    if user_id
      allow(controller).to receive(:doorkeeper_token).and_return(token(scopes, user_id))
    else
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
    end
  end

  def token(scopes, user_id)
    token = create(:access_token, resource_owner_id: user_id)
    allow(token).to receive(:accessible?).and_return(true)
    allow(token).to receive(:scopes).and_return(Doorkeeper::OAuth::Scopes.from_array(scopes))
    token
  end

  def stub_token_with_scopes(*scopes)
    stub_token(scopes: scopes)
  end

  def stub_token_with_user(user)
    stub_token(user_id: user.id)
  end

  def stub_content_filter
    allow_any_instance_of(ContentTypeFilter).to receive(:before).and_return(true)
  end

  def default_request(scopes: ["public"], user_id: nil)
    set_accept
    set_accept_language
    set_preconditions
    stub_content_filter
    stub_token(scopes: scopes, user_id: user_id)
  end

  def unauthenticated_request
    set_accept
    set_accept_language
    set_preconditions
    stub_content_filter
    stub_token
  end
end
