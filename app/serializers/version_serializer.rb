class VersionSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :changeset, :whodunnit, :created_at, :type, :href

  can_include :item

  def self.serializer_cache_key(model, context_hash)
    "#{model.class}/#{model.id}/#{model.created_at.to_i}/context-#{context_hash}"
  end

  def type
    "versions"
  end

  def href
    "/#{@model.item_type.downcase.pluralize}/#{@model.item_id}/versions/#{@model.id}"
  end

  def self.model_class
    PaperTrail::Version
  end
end
