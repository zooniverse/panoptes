module SidekiqConfig
  def self.namespace
    "panoptes_sidekiq_#{ Rails.env }"
  end

  def self.default_redis
    {
     host: 'localhost',
     port: 6378,
     db: 0
    }
  end

  def self.redis_url
    config = begin
               YAML.load(File.read(Rails.root.join('config/redis.yml')))
             rescue Errno::ENOENT
               { Rails.env => { 'sidekiq' => {  }  } }
             end
    config = default_redis.merge(config[Rails.env]['sidekiq'].symbolize_keys)

    if config.has_key? :password
      "redis://:#{ config[:password] }@#{ config[:host] }:#{ config[:port] }/#{ config[:db] }"
    else
      "redis://#{ config[:host] }:#{ config[:port] }/#{ config[:db] }"
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { namespace: SidekiqConfig.namespace, url: SidekiqConfig.redis_url }
end

Sidekiq.configure_server do |config|
  config.redis = { namespace: SidekiqConfig.namespace, url: SidekiqConfig.redis_url }
end
