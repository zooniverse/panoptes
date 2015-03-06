# This support package contains modules for authenticaiting
# devise users for request specs.
module ValidUserRequestHelper

    def sign_in_as_a_valid_user(user_factory=:user)
        @user ||= FactoryGirl.create user_factory, build_zoo_user: true
        @zoo_user ||= ZooniverseUser.find(@user.zooniverse_id.to_i)
        post_via_redirect user_session_path, 'user[display_name]' => @zoo_user.login,
                                             'user[password]' => @user.password
    end
end
