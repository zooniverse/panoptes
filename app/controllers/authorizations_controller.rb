class AuthorizationsController < Doorkeeper::AuthorizationsController
  include OauthTrust
  include Doorkeeper::Helpers::Controller
  before_action :allowed_response_type
  before_action :default_scopes
  before_action :allowed_scopes

  private

  def skip_authorization?
    client.first_party? || super
  end

  def allowed_response_type
    allowed = client.allowed_authorizations.include?(params[:response_type])
    head :unprocessable_entity unless allowed
  end
end
