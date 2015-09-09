class RedisConfig
  def self.sidekiq_pool
    ns = "panoptes_sidekiq_#{ Rails.env }"
    self.new("sidekiq").pool.with_namespace(ns)
  end

  def self.counter_pool
    ns = "panoptes_counter_#{ Rails.env }"
    self.new("counter").pool.with_namespace(ns)
  end

  def initialize(name)
    @name = name
  end

  def default_redis
    {
      host: 'localhost',
      port: 6379,
      db: 0,
      pool_size: 5
    }
  end

  def pool
    @pool ||= Pool.new pool_config
  end

  def pool_config
    {
      :url      => redis_url,
      :timeout  => 10.0,
      :pool     => { :size => pool_size }
    }
  end

  def pool_size
    if ::Sidekiq.server?
      Sidekiq.options[:concurrency]
    else
      config[:pool_size]
    end
  end

  def redis_url
    if config.has_key? :password
      "redis://:#{ config[:password] }@#{ config[:host] }:#{ config[:port] }/#{ config[:db] }"
    else
      "redis://#{ config[:host] }:#{ config[:port] }/#{ config[:db] }"
    end
  end

  def config
    @config ||= default_redis.merge(begin
                                      config = YAML.load(File.read(Rails.root.join('config/redis.yml')))
                                      config[Rails.env][@name].symbolize_keys
                                    rescue Errno::ENOENT, NoMethodError
                                      { }
                                    end)
  end

  class Pool < ::ConnectionPool
    attr_accessor :namespace

    def initialize(options = {})
      super(options.delete :pool) { Redis.new options }
    end

    def with_namespace(ns)
      clone.tap { |o| o.namespace = ns }
    end

    def checkout(*args, &block)
      conn = super(*args, &block)

      if conn && namespace
        return ::Redis::Namespace.new namespace, :redis => conn
      end

      conn
    end
  end
end
