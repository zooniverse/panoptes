class OrganizationContentSerializer
  include Serialization::PanoptesRestpack

  attributes :id, :language, :title, :description, :introduction, :announcement, :href

  can_include :organization
end
