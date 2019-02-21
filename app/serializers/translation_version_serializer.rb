class TranslationVersionSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :href, :created_at, :updated_at,
    :strings, :string_versions

  can_include :translation
end
