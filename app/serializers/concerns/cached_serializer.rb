module CachedSerializer
  extend ActiveSupport::Concern

  module ClassMethods
    def as_json(model, context)
      if Panoptes.flipper["cached_serializer"].enabled?
        cache_key = "#{model.class.to_s}/#{model.id}/#{model.updated_at.to_i}/context-#{Digest::MD5.hexdigest(context.to_json)}"

        Rails.cache.fetch(cache_key) do
          super
        end
      else
        super
      end
    end
  end
end
