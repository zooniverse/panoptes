class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    @user = User.from_omniauth(request.env['omniauth.auth'])

    unless @user.valid?
      # TODO Redirect to a page to edit user options
    else
      @user.save!
      redirect_url = request.env['omniauth.params']['redirect_url'] || 'https://zooniverse.org/'
      redirect_to redirect_url
    end
  end
end
