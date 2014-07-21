class AuthorizationsController < Doorkeeper::AuthorizationsController
  before_filter :allowed_reqest_type

  private

  def client
    @client ||= Doorkeeper::Application.where(uid: params[:client_id])
  end

  def allowed_request_type
    allowed = client.allowed_auth_types.include?(params[:request_type])
    head :bad_request unless allowed
  end
end
