module CachedSerializer
  extend ActiveSupport::Concern

  module ClassMethods
    def as_json(model, context)
      if Flipper.enabled?(:cached_serializer)
        cache_key = serializer_cache_key(model, Digest::MD5.hexdigest(context.to_json))

        Rails.cache.fetch(cache_key) do
          super
        end
      else
        super
      end
    end

    def serializer_cache_key(model, context_hash)
      "#{model.class}/#{model.id}/#{model.updated_at.to_i}/context-#{context_hash}"
    end
  end
end
