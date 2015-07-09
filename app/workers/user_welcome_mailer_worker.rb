class UserWelcomeMailerWorker
  include Sidekiq::Worker

  attr_reader :user, :project

  def perform(user_id, project_id=nil)
    @user = User.find(user_id)
    if @user && !@user.email.blank?
      @project_name = if project_id
        Project.find(project_id).try(:display_name)
      end
      UserWelcomeMailer.welcome_user(user, @project_name).deliver
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
