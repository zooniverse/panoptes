class OrganizationContentSerializer
  include RestPack::Serializer

  attributes :id, :language, :title, :description, :introduction, :announcement, :href

  can_include :organization
end
