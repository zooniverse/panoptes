module Serialization
  class PageWithCachedMetadata < SimpleDelegator
    def total_count
      scope_identifier = Digest::SHA256.hexdigest(except(:offset, :limit, :order).to_sql)
      cache_key = "PageWithCachedMetadata/#{scope_identifier}/total_count"

      @total_count ||= Rails.cache.fetch(cache_key) do
        super
      end

      # Ensure setting the instance variable cache in delegated monkey patched
      # AR object (kaminari), as other page count calculation methods
      # use it in serialize_meta restpack paging method
      __getobj__.instance_variable_set(:@total_count, @total_count)
    end
  end
end
