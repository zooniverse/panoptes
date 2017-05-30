class OrganizationSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include ContentSerializer
  include MediaLinksSerializer
  include CachedSerializer

  attributes :id, :display_name, :description, :introduction, :title, :href, :primary_language, :listed_at, :listed
  optional :avatar_src
  media_include :avatar, :background
  can_sort_by :display_name, :updated_at, :listed
  can_include :organization_contents, :organization_roles, :projects, :owners, :pages

  def title
    content[:title]
  end

  def description
    content[:description]
  end

  def introduction
    content[:introduction]
  end

  def content
    @content ||= _content
  end

  def avatar_src
    if avatar = @model.avatar
      avatar.external_link ? avatar.external_link : avatar.src
    else
      ""
    end
  end

  def fields
    %i(title description introduction)
  end

  def self.links
    links = super
    links["organizations.pages"] = {
                               href: "/organizations/{organizations.id}/pages",
                               type: "organization_pages"
                              }
    links
  end
end
