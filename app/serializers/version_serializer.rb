class VersionSerializer
  include RestPack::Serializer
  attributes :id, :changeset, :whodunnit, :created_at
  can_include :item

  #def changeset
    #@model.changeset
  #end

  def self.model_class
    PaperTrail::Version
  end
end
