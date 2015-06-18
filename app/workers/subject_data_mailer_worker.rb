class SubjectDataMailerWorker
  include Sidekiq::Worker

  def perform(project_id, s3_url, emails)
    SubjectDataMailer.subject_data(Project.find(project_id), s3_url.to_s, emails).deliver
  end
end
