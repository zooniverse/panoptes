class VersionSerializer
  include RestPack::Serializer
  attributes :id, :changeset, :whodunnit, :created_at, :type, :href

  can_include :item

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
