class TokensController < Doorkeeper::TokensController
  before_action :allowed_grants, only: :create
  before_action :default_scopes, only: :create
  before_action :allowed_scopes, only: :create

  private

  def client
    @client ||= Doorkeeper::Application.where(uid: params[:client_id]).first
  end

  def allowed_grants
    allowed = client.allowed_grants.include?(params[:grant_type]) 
    head :bad_reqest unless allowed
  end

  def allowed_scopes
    allowed = Doorkeeper::OAuth::Helpers::ScopeChecker.valid?(params[:scope], client.scopes)
    head :bad_reqest unless allowed
  end

  def default_scopes
    params[:scope] ||= client.max_scope.join(',')
  end
end
