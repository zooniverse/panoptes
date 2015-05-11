class MediumSerializer
  include RestPack::Serializer

  attributes :id, :href, :src, :content_type, :media_type, :external_link

  can_include :linked

  def media_type
    @model.type
  end

  def src
    @context[:post_urls] ? @model.put_url : @model.get_url
  end
end
