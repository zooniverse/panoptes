class TranslationSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :translated_id, :translated_type,
    :language, :strings, :href, :created_at, :updated_at

  can_include :translated

  can_filter_by :language

  # Add the polymorphic links to include all the resources
  # that have the inverse translation assocation
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

  # override the default polymorphic translated relation link.
  # Convert it to a straight belongs_to link based on reflection on the
  # translated_type / id association foreign key
  def add_links(model, data)
    data = super(model, data)
    polymorphic_belongs_to_link = data[:links].delete(:translated)
    singular_model_name = polymorphic_belongs_to_link[:type].singularize
    data[:links][singular_model_name] = polymorphic_belongs_to_link[:id]
    data
  end
end
