class AuthorizationsController < Doorkeeper::AuthorizationsController
  include OauthTrust
  before_action :allowed_request_type
  before_action :default_scopes
  before_action :allowed_scopes

  private

  def allowed_request_type
    allowed = client.allowed_auth_requests.include?(params[:request_type])
    head :unprocessable_entity unless allowed
  end
end
