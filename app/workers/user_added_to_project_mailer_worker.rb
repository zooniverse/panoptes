class UserAddedToProjectMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :user, :project

  def perform(user_id, project_id, roles)
    @user = User.find(user_id)
    if @user && @user.receives_email? && roles
      project = Project.find(project_id)
      UserAddedToProjectMailer.added_to_project(user, project, roles).deliver
    end
  rescue ActiveRecord::RecordNotFound
    nil
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError => e
    @user.update_attribute(:valid_email, false)
  end
end
