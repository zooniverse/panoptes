class ClassificationsExportSegmentSerializer
  include RestPack::Serializer

  attributes :id, :href, :started_at, :finished_at, :first_classification_id, :last_classification_id
  can_include :project, :workflow, :requester

  can_filter_by :workflow

  def self.page_href(page, options)
    return nil unless page

    project_id = options.filters.delete :project_id

    url = "#{href_prefix}/projects/#{project_id.try(:first)}/classifications_export_segments"

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
    "/projects/#{@model.project_id}/classifications_export_segments/#{@model.id}"
  end
end
