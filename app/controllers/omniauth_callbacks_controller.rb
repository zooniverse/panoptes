class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def callback
    @user = User.from_omniauth(request.env['omniauth.auth'])
    sign_in @user, event: :authentication
    redirect_to sign_in_redirect
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    flash[:alert] = "Sorry, an account with your email address already exists. Please log in normally or attempt a password reset if you've forgotten your password."
    redirect_to new_user_session_path
  end

  alias_method :facebook, :callback
  alias_method :google_oauth2, :callback

  private

  def sign_in_redirect
    request.env['omniauth.origin'] || 'https://zooniverse.org/'
  end
end
