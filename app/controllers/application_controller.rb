class ApplicationController < ActionController::Base
  include JSONApiRender
  include JSONApiResponses

  protect_from_forgery with: :null_session

  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  def unknown_route
    exception = ActionController::RoutingError.new("Not Found")
    response_body = JSONApiRender::JSONApiResponse.format_response_body(exception)
    respond_to do |format|
      format.html { raise exception }
      format.json { render status: :not_found, json: response_body }
      format.json_api { not_found(exception) }
    end
  end

  protected

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit(:email, :password, :password_confirmation, :login, :display_name,
               :credited_name, :global_email_communication,
               :project_email_communication, :beta_email_communication,
               :nasa_email_communication, :project_id, :minor_age)
    end

    devise_parameter_sanitizer.permit(:account_update) do |u|
      u.permit(:email, :password, :password_confirmation, :current_password, :display_name,
               :credited_name, :global_email_communication, :nasa_email_communication,
               :project_email_communication, :beta_email_communication)
    end
  end

  private

  def json_request?
    request.format.json?
  end
end
