class UserInfoScrubber

  DELETED_USER_NAME  = 'deleted_user'
  DELETED_USER_EMAIL_DOMAIN = '@zooniverse.org'

  class ScrubDisabledUserError < StandardError; end

  def self.scrub_personal_info!(user)
    @user = user
    if @user.disabled?
      message = "Can't scrub personal details of a disabled user with id: #{@user.id}"
      raise ScrubDisabledUserError.new(message)
    else
      scrub_details
    end
  end

  private

  def self.scrub_details
    @user.update_columns(email: nil)
  end
end
