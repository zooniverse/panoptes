class ProjectPageSerializer
  include RestPack::Serializer

  attributes :id, :href, :created_at, :updated_at, :url_key, :title,
    :language, :content, :type

  can_include :project
  can_filter_by :url_key, :language

  def self.page_href(page, options)
    return nil unless page

    project_id = options.filters.delete :project_id

    url = "#{self.href_prefix}/projects/#{project_id.try(:first)}/pages"

    params = []
    params << "page=#{page}" unless page == 1
    params << "page_size=#{options.page_size}" unless options.default_page_size?
    params << "include=#{options.include.join(',')}" if options.include.any?
    params << options.sorting_as_url_params if options.sorting.any?
    params << options.filters_as_url_params if options.filters.any?

    url += '?' + params.join('&') if params.any?
    url
  end

  def type
    "project_pages"
  end

  def href
    "/projects/#{@model.project_id}/pages/#{@model.id}"
  end
end
