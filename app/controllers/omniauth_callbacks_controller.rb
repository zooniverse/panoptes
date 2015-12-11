class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def callback
    @user = User.from_omniauth(request.env['omniauth.auth'])
    sign_in @user, event: :authentication
    redirect_to sign_in_redirect
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # TODO Redirect to a page to edit user options
  end

  alias_method :facebook, :callback
  alias_method :gplus, :callback

  private

  def sign_in_redirect
    request.env['omniauth.origin'] || 'https://zooniverse.org/'
  end
end
