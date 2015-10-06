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
    begin
      config = YAML.load(File.read(Rails.root.join('config/redis.yml')))
      config[Rails.env]['sidekiq'].symbolize_keys
    rescue Errno::ENOENT, NoMethodError
      { }
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { namespace: SidekiqConfig.namespace, url: SidekiqConfig.redis_url }
end

Sidekiq.configure_server do |config|
  config.redis = { namespace: SidekiqConfig.namespace, url: SidekiqConfig.redis_url }
  config.server_middleware do |chain|
    chain.add Sidekiq::Congestion::Limiter
  end
end

require 'sidetiq'
Sidetiq.configure do |config|
  config.utc = true
end

require 'sidetiq/web'
