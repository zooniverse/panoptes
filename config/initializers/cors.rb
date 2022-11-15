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
        { origins: cors_origin_allowed, resource: '/users*', credentials: true },
        { origins: cors_origin_allowed, resource: '/oauth/*', credentials: true },
        { origins: cors_origin_allowed, resource: '/unsubscribe', credentials: true }
      ]
    )
  end

  # setup CORS allow and block lists at boot time as they don't change
  # https://github.com/cyu/rack-cors#rack-configuration
  #
  # block list is a list of domain hosts to reject
  # NOTE: do not use strip! here as it returns nil if no changes and test this manually if you change the setup
  CORS_ORIGIN_HOST_REJECTIONS = ENV.fetch('CORS_ORIGINS_REJECT_HOSTS', '').split(',').map(&:strip).freeze
  # allow list is a regex to match against the origin host
  CORS_ORIGIN_REGEX = /#{ENV.fetch('CORS_ORIGINS_REGEX', '^https?:\/\/(127\.0\.0\.1|localhost|[a-z0-9-]+\.local)(:\d+)?$')}/.freeze

  # return a proc that can be used to configure the cors middleware
  def self.cors_origin_allowed
    proc do |source, _env|
      # explictly set the allowed origin to false at start
      allowed_origin = false

      # allow to reject some domains - allows multiple values via comma delimited string
      reject_origin = CORS_ORIGIN_HOST_REJECTIONS.map do |rejection_substring|
        URI.parse(source).host == rejection_substring
      end.any?

      # NOTE: can't use return guard clause in this proc due to localJumpError
      # https://ruby-doc.org/core-2.6/Proc.html#class-Proc-label-Lambda+and+non-lambda+semantics
      # so we have to use control flow and boolean logic to determine if this origin is allowed

      # test the origin via regex if not rejected
      allowed_origin = (source =~ CORS_ORIGIN_REGEX).present? unless reject_origin

      # allow the origin if:
      # 1. it is not explicitly rejected
      not_blocked_origin = !reject_origin
      # 2. and if it matches the allowed regex
      _allow_origin = not_blocked_origin && allowed_origin
    end
  end
end

Panoptes.cors_config
