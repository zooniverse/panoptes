# This support package contains modules for authenticaiting
# devise users for request specs.
module ValidUserRequestHelper

    def sign_in_as_a_valid_user(user_factory=:user)
        @user ||= FactoryGirl.create user_factory
        post_via_redirect user_session_path, 'user[display_name]' => @user.display_name,
                                             'user[password]' => @user.password
    end
end
