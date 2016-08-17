class UserInfoChangedMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(user_id, info)
    @user = User.find(user_id)
    if @user && !@user.email.blank?
      UserInfoChangedMailer.user_info_changed(user, info).deliver
    end
  rescue ActiveRecord::RecordNotFound
    nil
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError => e
    @user.update_attribute(:valid_email, false)
  end
end
