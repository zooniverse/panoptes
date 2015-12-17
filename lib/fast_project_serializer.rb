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
        'first_href' => '/projects?homepage=true',
        'previous_href' => page_href(paginated.prev_page),
        'next_href' => page_href(paginated.next_page),
        'last_href' => page_href(paginated.total_pages)
      }
    }
  end

  def page_href(page_number)
    return unless page_number
    "/projects?homepage=true&page=#{ page_number }&page_size=#{ page_size }"
  end

  def project_data(project)
    {
      'id' => project.id.to_s,
      'display_name' => project.display_name,
      'description' => project.project_contents.first.description,
      'slug' => project.slug,
      'redirect' => project.redirect,
      'avatar_src' => avatar_src(project.avatar)
    }
  end

  def avatar_src(avatar)
    return unless avatar
    avatar.external_link ? avatar.src : "//#{ avatar.src }"
  end
end
