class OrganizationSerializer
  include Serialization::PanoptesRestpack
  include OwnerLinkSerializer
  include MediaLinksSerializer
  include CachedSerializer

  attributes :id, :display_name, :description, :introduction, :title, :href,
    :primary_language, :listed_at, :listed, :slug, :urls, :categories, :announcement
  optional :avatar_src
  media_include :avatar, :background, :attached_images
  can_filter_by :display_name, :slug, :listed
  can_include :organization_roles, :projects, :owners, :pages

  def avatar_src
    if avatar = @model.avatar
      avatar.external_link ? avatar.external_link : avatar.src
    else
      ""
    end
  end

  def self.links
    links = super
    links["organizations.pages"] = {
                               href: "/organizations/{organizations.id}/pages",
                               type: "organization_pages"
                              }
    links
  end

  def urls
    urls = @model.urls.dup
    TasksVisitors::InjectStrings.new(@model.url_labels).visit(urls)
    urls
  end
end
