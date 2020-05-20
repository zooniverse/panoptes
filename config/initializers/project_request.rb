module Panoptes
  def self.project_request
    @project_request ||= OpenStruct.new(
      base_url: ENV.fetch(
        'PROJECT_REQUEST_BASE_URL',
        'http://localhost:3735'
      ),
      recipients: ENV.fetch(
        'PROJECT_REQUEST_RECIPIENTS',
        'no-reply@zooniverse.org'
      ).split(','),
      bcc: ENV.fetch('PROJECT_REQUEST_BCC', '').split(',')
    )
  end
end

Panoptes.project_request
