class SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, if: -> { json_request? && action_name == 'destroy' }
  after_action :set_csrf_headers, only: %i[create destroy]
  after_action :set_csrf_headers, if: -> { :json_request? && action_name == 'new' }

  def new
    respond_to do |format|
      format.html { super }
      format.json { login_options }
    end
  end

  def create
    respond_to do |format|
      format.html { super }
      format.json { create_from_json }
    end
  end

  def destroy
    respond_to do |format|
      format.json { destroy_from_json }
      format.html { super }
    end
  end

  private

  def create_from_json
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    yield resource if block_given?
    resource_scope = resource.class.where(id: resource.id)
    render status: 200, json: UserSerializer.resource({}, resource_scope, { include_private: true })
  end

  def destroy_from_json
    revoke_access_tokens! if doorkeeper_token
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    yield if block_given?
    head :no_content
  end

  def login_options
    opts = { login: '/users/sign_in' }
    Devise.omniauth_providers.each do |provider|
      opts[provider] = "/users/auth/#{provider}"
    end
    render status: 200, json: opts
  end

  def set_csrf_headers
    response.headers['X-CSRF-Param'] = request_forgery_protection_token.to_s
    response.headers['X-CSRF-Token'] = form_authenticity_token.to_s
  end

  def revoke_access_tokens!

    application_id_to_revoke = doorkeeper_token&.application_id
    return unless application_id_to_revoke
    user = doorkeeper_token&.resource_owner_id
    Doorkeeper::AccessToken.revoke_all_for(
      application_id_to_revoke,
      user
    )
  end
end
