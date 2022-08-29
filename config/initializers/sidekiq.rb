module SidekiqConfig
  def self.redis_url
    ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
  end
end

require 'redis'
Redis.exists_returns_integer = false

Sidekiq.configure_client do |config|
  config.redis = { url: SidekiqConfig.redis_url }
end

Sidekiq.configure_server do |config|
  config.redis = { url: SidekiqConfig.redis_url }
  config.server_middleware do |chain|
    chain.add Sidekiq::Congestion::Limiter
  end

  #Sidekiq-cron: load recurring jobs from schedule.yml
  schedule_file = 'config/schedule.yml'
  if File.exists?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

Sidekiq::Extensions.enable_delay!

require 'sidetiq'
Sidetiq.configure do |config|
  config.utc = true
end

require 'sidetiq/web'
