require 'doorkeeper/application_controller'

class TokensController < Doorkeeper::TokensController
  include OauthTrust
  before_action :allowed_grants, only: :create
  before_action :default_scopes, only: :create, if: :non_code_request
  before_action :allowed_scopes, only: :create, if: :non_code_request

  private

  def allowed_grants
    allowed = client.allowed_grants.include?(params[:grant_type])
    head :unprocessable_entity unless allowed
  end

  def non_code_request
    params[:grant_type] == 'password' || params[:grant_type] == 'client_credentials'
  end
end
