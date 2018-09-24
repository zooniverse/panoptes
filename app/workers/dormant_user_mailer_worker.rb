class DormantUserMailerWorker
  include Sidekiq::Worker

  attr_reader :user

  def perform(user_id)
    user = User.find(user_id)
    if user.receives_email?
      DormantUserMailer.email_dormant_user(user).deliver
    end
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError => e
    user.update_attribute(:valid_email, false)
  end
end
