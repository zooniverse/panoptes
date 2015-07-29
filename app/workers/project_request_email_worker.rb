class ProjectRequestEmailWorker
  include Sidekiq::Worker

  def perform(type, project_id)
    if Rails.env == 'production' || Rails.env == 'test'
      ProjectRequestMailer.project_request(type, project_id).deliver
    end
  end
end
