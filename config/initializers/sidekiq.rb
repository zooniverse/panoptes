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
end

Sidekiq.configure_server do |config|
  config.redis = { url: SidekiqConfig.redis_url }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
    chain.add Sidekiq::Congestion::Limiter
  end

  SidekiqUniqueJobs::Server.configure(config)

  # Sidekiq-cron: loads recurring jobs from config/schedule.yml
  schedule_file = 'config/schedule.yml'
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

Sidekiq::Extensions.enable_delay!
