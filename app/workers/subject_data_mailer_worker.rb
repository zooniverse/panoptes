class SubjectDataMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(project_id, s3_url, emails)
    SubjectDataMailer.subject_data(Project.find(project_id), s3_url.to_s, emails).deliver
  end
end
