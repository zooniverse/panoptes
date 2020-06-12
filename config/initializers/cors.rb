require 'ostruct'
module Panoptes
  def self.cors_config
    @cors_config ||= OpenStruct.new(
      headers: :any,
      request_methods: %w[delete get post options put head],
      expose: %w[ETag X-CSRF-Param X-CSRF-Token],
      max_age: ENV.fetch('CORS_MAX_AGE', 300).to_i,
      allows: [
        { origins: '*', resource: '/api/*' },
        { origins: '*', resource: '/graphql' },
        { origins: cors_origins_regex, resource: '/users*', credentials: true },
        { origins: cors_origins_regex, resource: '/oauth/*', credentials: true }
      ]
    )
  end

  def self.cors_origins_regex
    cors_origins = ENV.fetch(
      'CORS_ORIGINS_REGEX',
      '^https?:\/\/(127\.0\.0\.1|localhost|[a-z0-9-]+\.local)(:\d+)?$'
    )
    /#{cors_origins}/
  end
end

Panoptes.cors_config
