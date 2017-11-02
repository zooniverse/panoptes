module Serialization
  class PageWithCachedMetadata < SimpleDelegator
    def total_count
      scope_identifier = Digest::SHA256.hexdigest(except(:offset, :limit, :order).to_sql)
      cache_key = "PageWithCachedMetadata/#{scope_identifier}/total_count"

      @total_count ||= Rails.cache.fetch(cache_key) do
        super
      end

      # Make sure to fill instance variable cache in object, so that other methods
      # can use it.
      __getobj__.instance_variable_set(:@total_count, @total_count)
    end
  end
end
