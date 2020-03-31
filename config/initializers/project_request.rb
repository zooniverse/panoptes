module Panoptes
  def self.project_request
    @project_request ||= OpenStruct
      .new({
          base_url: ENV['PROJECT_REQUEST_BASE_URL'] || 'http://localhost:3735',
          recipients: ENV['PROJECT_REQUEST_RECIPIENTS']&.split(',') || ['no-reply@zooniverse.org'],
          bcc: ENV['PROJECT_REQUEST_BCC']&.split(',')
      })
  end
end

Panoptes.project_request
