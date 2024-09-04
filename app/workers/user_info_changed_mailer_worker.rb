class UserInfoChangedMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :user, :project

  def perform(user_id, info, previous_email=nil)
    @user = User.find(user_id)
    if @user && @user.receives_email?
      UserInfoChangedMailer.user_info_changed(user, info, previous_email).deliver
    end
  rescue ActiveRecord::RecordNotFound
    nil
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError => e
    @user.update_attribute(:valid_email, false)
  end
end
