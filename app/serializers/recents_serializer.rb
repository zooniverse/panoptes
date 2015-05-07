class RecentsSerializer
  include RestPack::Serializer

  attributes :id, :created_at, :locations
  can_include :project, :workflow, :subject

  def self.model_class
    Classification
  end

  def self.key
    'recents'
  end

  def self.links
    links = super
    links["#{key}.subject"] = { href: "/subjects/{#{key}.subject}", type: "subjects" }
    links
  end

  def locations
    @model.locations.map{ |loc| {loc.content_type => loc.get_url} }
  end
end

