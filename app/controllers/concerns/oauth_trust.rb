module OauthTrust
  extend ActiveSupport::Concern

  def client
    @client ||= client_from_params
  end

  def allowed_scopes
    allowed = Doorkeeper::OAuth::Helpers::ScopeChecker.valid?(params[:scope], client.scopes)
    head :unprocessable_entity unless allowed
  end

  def default_scopes
    params[:scope] ||= client.default_scope.join(' ')
  end

  private

  def client_from_params
    if client_id = params[:client_id]
      Doorkeeper::Application.where(uid: client_id).first
    end
  end
end
