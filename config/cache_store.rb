module Panoptes
  module ElastiCache
    def self.client
      if cluster_name = ENV["ELASTIC_CACHE"]
        Dalli::ElastiCache.new("#{cluster_name}:11211")
      end
    end

    def self.options
      { expires_in: expires_in, compress: compress, pool_size: pool_size }
    end

    def self.expires_in
      ENV.fetch("CACHE_EXPIRES_IN", 5.minutes).to_i.seconds
    end

    def self.compress
      ENV.fetch("CACHE_COMPRESS", true)
    end

    def self.pool_size
      ENV.fetch("CACHE_POOL_SIZE", 16).to_i
    end
  end
end
