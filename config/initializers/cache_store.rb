module Panoptes
  module ElastiCache
    def self.client
      if cluster_name = ENV["ELASTIC_CACHE"]
        Dalli::ElastiCache.new("#{cluster_name}:11211")
      end
    end

    def self.options
      { expires_in: expires_in, compress: compress }
    end

    def self.expires_in
      ENV.fetch("CACHE_EXPIRES_IN", 5.minutes)
    end

    def self.compress
      ENV.fetch("CACHE_COMPRESS", true)
    end
  end
end

# change the ENV cache store config to use AWS Elastic Cache
if cache_client = Panoptes::ElastiCache.client
  Rails.application.config.cache_store = :dalli_store,
    cache_client.servers,
    Panotes::ElastiCache.options
end
