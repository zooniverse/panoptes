class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def facebook
    @user = User.from_omniauth(request.env['omniauth.auth'])

    unless @user.valid?
      # TODO Redirect to a page to edit user options
    else
      @user.save!
      sign_in @user, event: :authentication
      redirect_to sign_in_redirect
    end
  end
  
  private
  def sign_in_redirect
    request.env['omniauth.origin'] || 'https://zooniverse.org/'
  end
end
