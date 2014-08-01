class UserInfoScrubber

  DELETED_USER_NAME  = 'deleted_user'
  DELETED_USER_EMAIL = 'deleted_user@zooniverse.org'

  class ScrubDisabledUserError < StandardError; end

  def self.scrub_personal_info!(user)
    if user.disabled?
      raise ScrubDisabledUserError.new("Can't scrub personal details of a disabled user with id: #{user.id}")
    else
      user.update_columns( email: DELETED_USER_EMAIL, display_name: DELETED_USER_NAME )
    end
  end
end
