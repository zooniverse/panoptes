class TranslationSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :translated_id, :translated_type,
    :language, :strings, :created_at, :updated_at

  can_include :translated

  can_filter_by :language
end
