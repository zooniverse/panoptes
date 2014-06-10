require "zlib"

class UserInfoScrubber

  DELETED_USER_NAME  = 'deleted_user'
  DELETED_USER_EMAIL = 'deleted_user@zooniverse.org'

  class ScrubDisabledUserError < StandardError; end

  class << self

    def scrub_personal_info!(user)
      if user.disabled?
        raise ScrubDisabledUserError.new("Can't scrub personal details of a disabled user with id: #{user.id}")
      else
        hashed_login_string = Zlib.crc32(user.login).to_s
        user.update_columns( email: DELETED_USER_EMAIL,
                             display_name: DELETED_USER_NAME,
                             login: hashed_login_string )
      end
    end
  end
end
