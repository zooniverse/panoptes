class UserWelcomeMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(user_id, project_id=nil)
    user = User.find(user_id)
    if user&.receives_email?
      if project_id
        project = Project.find(project_id)
        project_name = project&.display_name
      end
      UserWelcomeMailer.welcome_user(user, project_name).deliver
    end
  rescue ActiveRecord::RecordNotFound
    nil
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError => e
    user.update_attribute(:valid_email, false)
  end
end
