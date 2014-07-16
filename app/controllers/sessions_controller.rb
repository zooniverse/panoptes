class SessionsController < Devise::SessionsController
  include JSONApiRender
  after_filter :set_csrf_headers, only: [:create, :destroy]

  def new
    respond_to do |format|
      format.html { super }
      format.json_api { login_options }
    end
  end

  def create
    respond_to do |format|
      format.html { super }
      format.json_api { create_from_json }
    end
  end

  def destroy
    respond_to do |format|
      format.html { super }
      format.json_api { destroy_from_json }
    end
  end

  private

  def create_from_json
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    yield resource if block_given?
    render status: 200, json_api: UserSerializer.resource(resource)
  end

  def destroy_from_json 
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    yield if block_given?
    head :no_content
  end

  def login_options
    opts = { login: '/users/sign_in' }
    Devise.omniauth_providers.each do |provider|
      opts[provider] = "/users/auth/#{provider}"
    end
    render status: 200, json_api: opts
  end

  def set_csrf_headers
    response.headers['X-CSRF-Param'] = request_forgery_protection_token.to_s
    response.headers['X-CSRF-Token'] = form_authenticity_token.to_s
  end
end
