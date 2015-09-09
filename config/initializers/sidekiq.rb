Sidekiq.configure_client do |config|
  config.redis = RedisConfig.sidekiq_pool
end

Sidekiq.configure_server do |config|
  config.redis = RedisConfig.sidekiq_pool
end
