class UserWelcomeMailerWorker
  include Sidekiq::Worker

  attr_reader :user, :project

  def perform(user_id, project_id=nil)
    if @user = User.find(user_id)
      @project = Project.find(project_id) if project_id
      welcome_mailer.deliver
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  def welcome_mailer
    if project
      UserWelcomeMailer.welcome_user(user)
    else
      UserWelcomeMailer.project_welcome_user(user, project)
    end
  end
end
