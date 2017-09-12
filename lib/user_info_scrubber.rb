class UserInfoScrubber

  DELETED_USER_NAME  = 'deleted_user'
  DELETED_USER_EMAIL_DOMAIN = '@zooniverse.org'

  class ScrubDisabledUserError < StandardError; end

  def self.scrub_personal_info!(user)
    if user.disabled?
      message = "Can't scrub personal details of a disabled user with id: #{user.id}"
      raise ScrubDisabledUserError.new(message)
    end

    scrub_details(user)
  end

  def self.scrub_details(user)
    user.email = "noreply-#{SecureRandom.hex(4)}@zooniverse.org"
    user.current_sign_in_ip = nil
    user.last_sign_in_ip = nil
    user.display_name = "Deleted user #{user.id}"
    user.login = "deleted-#{user.id}"
    user.credited_name = nil
    user.password = user.password_confirmation = SecureRandom.hex(16)
    user.global_email_communication = false
    user.project_email_communication = false
    user.beta_email_communication = false
    user.valid_email = false
    user.private_profile = true
    user.api_key = nil
    user.tsv = nil
    user.save!
    user
  end
end
