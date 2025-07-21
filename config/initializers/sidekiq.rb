# frozen_string_literal: true

require 'sidekiq-status'

module SidekiqConfig
  def self.redis_url
    ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: SidekiqConfig.redis_url }
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
  Sidekiq::Status.configure_client_middleware config, expiration: 24.hours
end

Sidekiq.configure_server do |config|
  config.redis = { url: SidekiqConfig.redis_url }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 24.hours
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
    chain.add Sidekiq::Congestion::Limiter
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 24.hours
  end

  SidekiqUniqueJobs::Server.configure(config)

  # Sidekiq-cron: loads recurring jobs from config/schedule.yml
  schedule_file = 'config/schedule.yml'
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

Sidekiq::Extensions.enable_delay!
