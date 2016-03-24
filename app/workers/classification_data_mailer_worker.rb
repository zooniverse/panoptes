class ClassificationDataMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(project_id, s3_url, emails)
    return unless emails.present?
    ClassificationDataMailer.classification_data(Project.find(project_id), s3_url.to_s, emails).deliver
  end
end
