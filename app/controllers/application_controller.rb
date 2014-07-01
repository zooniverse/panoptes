class ApplicationController < ActionController::Base

  include JSONApiRender

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  class PanoptesControllerError < StandardError; end

  rescue_from ActiveRecord::RecordNotFound,   with: :not_found

  before_filter :configure_permitted_parameters, if: :devise_controller?

  def unknown_route
    exception = ActionController::RoutingError.new("Not Found")
    not_found(exception)
  end

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_up) do |u|
        u.permit(:email, :password, :password_confirmation, :login, :name)
      end
    end

    def not_found(exception)
      render status: :not_found, json_api: exception
    end
end
