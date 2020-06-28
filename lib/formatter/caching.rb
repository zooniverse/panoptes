# frozen_string_literal: true

module Formatter
  class Caching
    attr_reader :cache_resource, :formatter

    def initialize(cache_resource, formatter)
      @cache_resource = cache_resource
      @formatter = formatter
    end

    private

    def respond_to_missing?(name, include_private=false)
      @formatter.respond_to?(name, include_private)
    end

    # rubocop:disable Style/MethodMissingSuper
    def method_missing(method, *_args, &_block)
      # look in the cache_resource data hash for the attribute name
      if (cache_resource_value = @cache_resource&.data&.dig(method.to_s))
        cache_resource_value
      else
        # fallback to the formatter if we didn't find the data in the cache
        @formatter.send(method)
      end
    end
    # rubocop:enable Style/MethodMissingSuper
  end
end