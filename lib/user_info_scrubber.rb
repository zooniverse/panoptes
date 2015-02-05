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
    begin
      tries ||= 2
      @user.update_columns(email: nil, display_name: scrubbed_display_name(tries))
    rescue ActiveRecord::RecordNotUnique => e
      retry if (tries -= 1) > 0
      raise e
    end
  end

  def self.scrubbed_display_name(tries)
    suffix = tries > 0 ? tries : nil
    "#{DELETED_USER_NAME}_#{SecureRandom.uuid}#{suffix}"
  end
end
