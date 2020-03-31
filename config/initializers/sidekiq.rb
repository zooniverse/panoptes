module SidekiqConfig
  def self.namespace
    "panoptes_sidekiq_#{ Rails.env }"
  end

  def self.default_redis
    {
      host: 'localhost',
      port: 6379,
      db: 0
    }
  end

  def self.redis_url
    config = default_redis.merge(read_redis_config)

    if config.has_key? :password
      "redis://:#{ config[:password] }@#{ config[:host] }:#{ config[:port] }/#{ config[:db] }"
    else
      "redis://#{ config[:host] }:#{ config[:port] }/#{ config[:db] }"
    end
  end

  def self.read_redis_config
    {
      host: ENV['SIDEKIQ_HOST'] || 'redis',
      port: ENV['SIDEKIQ_PORT'] || 6379
    }
  end

  def self.queues
    if ENV['SIDEKIQ_QUEUES']
      # This works with a string, i.e. queue_1,queue_2,queue_3
      # Weights as arrays, i.e. [ [queue_1, 4], [queue_2, 3] ]
      # would require refactoring to parse correctly.
      ENV['SIDEKIQ_QUEUES'].split(',')
    else
      ['default']
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: SidekiqConfig.redis_url }
end

Sidekiq.configure_server do |config|
  config.redis = { url: SidekiqConfig.redis_url }
  config.server_middleware do |chain|
    chain.add Sidekiq::Congestion::Limiter
  end

  config.options[:concurrency] = ENV['SIDEKIQ_CONCURRENCY'].to_i || 5
  config.options[:verbose] = ENV['SIDEKIQ_VERBOSE'] || false
  config.options[:logfile] = ENV['SIDEKIQ_LOGFILE'] || './log/sidekiq.log'
  config.options[:pidfile] = ENV['SIDEKIQ_PIDFILE'] || './tmp/pids/sidekiq.pid'
  config.options[:timeout] = ENV['SIDEKIQ_TIMEOUT'].to_i || 8
  config.options[:queues] = SidekiqConfig.queues
end

Sidekiq::Extensions.enable_delay!

require 'sidetiq'
Sidetiq.configure do |config|
  config.utc = true
end

require 'sidetiq/web'
