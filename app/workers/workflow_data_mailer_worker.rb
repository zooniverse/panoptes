class WorkflowDataMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(resource_id, resource_type, url, emails)
    return unless emails.present?
    WorkflowDataMailer.workflow_data(Project.find(resource_id), url.to_s, emails).deliver
  end
end
