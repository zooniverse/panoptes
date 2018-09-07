class DormantUserMailerWorker
  include Sidekiq::Worker

  attr_reader :user

  def perform(user_id)
    user = User.find(user_id)
    if user.receives_email?
      DormantUserMailer.email_dormant_user(user).deliver
    end
  end
end
