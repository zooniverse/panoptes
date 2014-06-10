require "zlib"

class UserInfoScrubber

  DELETED_USER_NAME  = 'deleted_user'
  DELETED_USER_EMAIL = 'deleted_user@zooniverse.org'

  class << self

    def scrub_personal_info!(user)
      return false if user.disabled?
      hashed_login_string = Zlib.crc32(user.login).to_s
      user.update_columns( email: DELETED_USER_EMAIL,
                           display_name: DELETED_USER_NAME,
                           login: hashed_login_string )
    end
  end
end
