class TranslationSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :translated_id, :translated_type,
    :language, :strings, :string_versions,
    :href, :created_at, :updated_at

  can_include :translated, :published_version

  can_filter_by :language

  def strings
    requested_version.strings
  end

  def string_versions
    requested_version.string_versions
  end

  def requested_version
    if @context[:published]
      @model.published_version || @model
    else
      @model
    end
  end

  # Add the polymorphic links to include all the resources
  # that have the inverse translation assocation
  def self.links
    links = super
    Translation.translated_model_names.each do |model_name|
      link_key = "#{key}.#{model_name}"
      serializer = "#{model_name}_serializer".classify.constantize

      links[link_key] = {
        href: "/#{serializer.url}/{#{link_key}}",
        type: model_name.pluralize.to_sym
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
