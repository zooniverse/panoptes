class ProjectPageSerializer
  include RestPack::Serializer

  attributes :id, :href, :created_at, :updated_at, :url_key, :title,
    :language, :content, :type

  can_include :project
  can_filter_by :url_key, :language

  def type
    "project_pages"
  end
end
