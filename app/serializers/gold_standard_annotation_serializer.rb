class GoldStandardAnnotationSerializer
  include Serialization::PanoptesRestpack
  include NoCountSerializer
  include CachedSerializer

  attributes :id, :annotations, :created_at, :updated_at, :metadata

  can_include :project, :user, :workflow

  def self.key
    :classifications
  end

  def id
    @model.classification_id.to_s
  end

  def add_links(model, data)
    data = super(model, data)
    data[:links][:subjects] = model.subject_id.to_s
    data
  end

  def self.links
    links = super
    links["#{key}.subjects"] = {
      type: "subjects",
      href: "/subjects/{#{key}.subjects}"
    }
    links
  end
end
