# frozen_string_literal: true

# This support package contains modules for authenticaiting
# devise users for request specs.
module ValidUserRequestHelper
  def sign_in_as_a_valid_user(user_factory=:user)
    @user ||= FactoryBot.create user_factory
    post user_session_path, params: { 'user[login]' => @user.login,
                                      'user[password]' => @user.password }
  end
end
