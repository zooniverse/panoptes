class OrganizationSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include MediaLinksSerializer
  include CachedSerializer

  CONTENT_FIELDS = %i(title description introduction announcement).freeze

  attributes :id, :display_name, :description, :introduction, :title, :href,
    :primary_language, :listed_at, :listed, :slug, :urls, :categories, :announcement
  optional :avatar_src
  media_include :avatar, :background, :attached_images
  can_filter_by :display_name, :slug, :listed
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

  def announcement
    content[:announcement]
  end

  def avatar_src
    if avatar = @model.avatar
      avatar.external_link ? avatar.external_link : avatar.src
    else
      ""
    end
  end

  def content
    return @content if @content
    content = @model.primary_content.attributes.with_indifferent_access
    content.default = ""
    @content = content.slice(*CONTENT_FIELDS)
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
