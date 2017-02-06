class OrganizationSerializer
  include RestPack::Serializer
  include ContentSerializer
  include MediaLinksSerializer

  attributes :id, :display_name, :description, :introduction, :title, :href, :primary_language
  optional :avatar_src
  media_include :avatar, :background
  can_include :organization_contents, :organization_roles, :projects
  can_sort_by :display_name, :updated_at, :listed_at

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
end
