class VersionSerializer
  include RestPack::Serializer
  attributes :id, :changeset, :whodunnit, :created_at, :links

  def self.model_class
    PaperTrail::Version
  end

  def item_href
    "/#{ @model.item.class.model_name.route_key }/#{ @model.item.id }"
  end

  def item_type
    @model.item.class.model_name.singular
  end

  def links
    { item: { id: @model.item.id.to_s,
              href: item_href,
              type: item_type } }
  end

  def self.links
    { } 
  end
end
