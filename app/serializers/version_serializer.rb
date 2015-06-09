class VersionSerializer
  include RestPack::Serializer
  include BlankTypeSerializer
  attributes :id, :changeset, :whodunnit, :created_at

  can_include :item

  def self.model_class
    PaperTrail::Version
  end
end
