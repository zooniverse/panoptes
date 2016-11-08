class OrganizationContentSerializer
  include RestPack::Serializer
  attributes :id, :language, :title, :description, :introduction, :href

  can_include :organization
end
