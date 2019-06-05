class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def callback
    if resource = current_user
      flash[:alert] = I18n.t("devise.failure.already_authenticated")
      redirect_to after_sign_in_path_for(resource)
    else
      @user = User.from_omniauth(request.env['omniauth.auth'])
      sign_in @user, event: :authentication
      redirect_to sign_in_redirect
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    flash[:alert] = "Sorry, an account with your email address already exists. Please log in with your Zooniverse account, or attempt a password reset if you've forgotten your password."
    redirect_to new_user_session_path
  end

  alias_method :facebook, :callback
  alias_method :google_oauth2, :callback

  private

  def sign_in_redirect
    request.env['omniauth.origin'] || 'https://zooniverse.org/'
  end
end
