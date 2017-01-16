module ModelCacheKey
  def model_cache_key(method_name)
    "#{self.class}/#{id.to_i}/#{updated_at.to_i}/#{method_name}"
  end
end
