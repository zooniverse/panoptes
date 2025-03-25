module Panoptes
  module Cache
    def self.servers
      ENV.fetch('MEMCACHE_SERVERS', '')
    end

    def self.enabled?
      ENV.key?('MEMCACHE_SERVERS')
    end

    def self.options
      { expires_in: expires_in, compress: compress, pool_size: pool_size }
    end

    def self.expires_in
      ENV.fetch('CACHE_EXPIRES_IN', 5.minutes).to_i.seconds
    end

    def self.compress
      ENV.fetch('CACHE_COMPRESS', true)
    end

    def self.pool_size
      ENV.fetch('RAILS_MAX_THREADS', 8).to_i
    end
  end
end
