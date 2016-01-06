class FastProjectSerializer
  attr_accessor :params

  def initialize(params)
    @params = params
  end

  def serialize
    {
      'projects' => paginated.collect{ |project| project_data project },
      'meta' => meta
    }.as_json
  end

  def page
    params.fetch(:page, 1).to_i
  end

  def page_size
    params.fetch(:page_size, 20).to_i
  end

  def query
    @query ||= Project.where(launch_approved: true)
      .order(:launched_row_order)
      .eager_load(:avatar, :project_contents)
  end

  def paginated
    @paginated ||= query.page(page).per page_size
  end

  def meta
    {
      'projects' => {
        'page' => page,
        'page_size' => page_size,
        'count' => paginated.total_count,
        'include' => ['avatar'],
        'page_count' => paginated.total_pages,
        'previous_page' => paginated.prev_page,
        'next_page' => paginated.next_page,
        'first_href' => '/projects?simple=true',
        'previous_href' => page_href(paginated.prev_page),
        'next_href' => page_href(paginated.next_page),
        'last_href' => page_href(paginated.total_pages)
      }
    }
  end

  def page_href(page_number)
    return unless page_number
    "/projects?simple=true&page=#{ page_number }&page_size=#{ page_size }"
  end

  def project_data(project)
    contents = project.project_contents
    content = content_for project

    {
      'id' => project.id.to_s,
      'display_name' => project.display_name,
      'description' => content.description,
      'title' => content.title,
      'slug' => project.slug,
      'redirect' => project.redirect,
      'avatar_src' => avatar_src(project.avatar),
      'available_languages' => contents.map(&:language)
    }
  end

  def avatar_src(avatar)
    return unless avatar
    avatar.external_link ? avatar.src : "//#{ avatar.src }"
  end

  def content_for(project)
    find_content_for(project, params[:language]) ||
    find_content_for(project, project.primary_language) ||
    project.project_contents.first
  end

  def find_content_for(project, language)
    project.project_contents.find do |content|
      content.language == language
    end
  end
end
