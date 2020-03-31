require 'ostruct'
module Panoptes
  def self.cors_config
    @cors_config ||= OpenStruct.new({
                      headers: :any,
                      request_methods: %w[ delete get post options put head ],
                      expose: %w[ ETag X-CSRF-Param X-CSRF-Token ],
                      max_age: 300,
                      allows: [
                        { "origins" => '*', "resource" => '/api/*' },
                        { "origins" => '*', "resource" => '/graphql' },
                        {
                          "origins" => ENV['CORS_ORIGINS_USERS'] || default_origins,
                          "resource" => '/users*',
                          "credentials" => true
                        },
                        {
                          "origins" => ENV['CORS_ORIGINS_OAUTH'] || default_origins,
                          "resource" => '/oauth/*',
                          "credentials" => true
                        }
                      ]
                    })
  end

  def self.default_origins
    /^https?:\/\/(127\.0\.0\.1|localhost|[a-z0-9-]+\.local)(:\d+)?$/
  end
end

Panoptes.cors_config
