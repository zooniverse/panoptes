class WorkflowDataMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(resource_id, resource_type, s3_url, emails)
    return unless emails.present?
    WorkflowDataMailer.workflow_data(Project.find(resource_id), s3_url.to_s, emails).deliver
  end
end
