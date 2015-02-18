class RecentsSerializer
  include RestPack::Serializer

  attributes :id, :created_at, :updated_at, :locations
  can_include :project, :workflow
  
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

  def add_links(model, data)
    data = super
    data[:links][:subject] = model.subject_id.to_s
    data
  end

  def id
    "#{@context[:type]}-#{@model.id}-#{@model.subject_id}"
  end
end

