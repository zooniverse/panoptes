class TranslationSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :translated_id, :translated_type,
    :language, :strings, :href, :created_at, :updated_at

  can_include :translated

  can_filter_by :language

  # TODO: add the instance href in to the serializer if it's not htere by default.

  def self.links
    links = super
    Translation.translated_model_names.each do |model_name|
      singular = model_name.singular
      link_key = "#{key}.#{singular}"
      serializer = "#{singular}_serializer".classify.constantize
      links[link_key] = {
        href: "/#{serializer.url}/{#{link_key}}",
        type: model_name.plural.to_sym
      }
    end
    links
  end
end
